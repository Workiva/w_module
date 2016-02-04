library w_module.alpha.deferred_module_transformer;

import 'dart:async';
import 'dart:mirrors' as mirrors;

import 'package:analyzer/analyzer.dart';
import 'package:barback/barback.dart';
import 'package:source_span/source_span.dart';
import 'package:transformer_utils/transformer_utils.dart';

import 'package:w_module/alpha/annotations.dart' as annotations;

String _getReflectedName(Type type) =>
    mirrors.MirrorSystem.getName(mirrors.reflectType(type).simpleName);

/// Aggregate transformer that generates the implementation logic for a deferred
/// module. The generated implementation takes care of the following:
///
/// - Loading the deferred library that contains the real module class when the
///   deferred module's "onLoad" event occurs.
/// - Deferring the availability of certain parts of the module's contract (API,
///   Components, and Events) until the underlying module has actually been
///   loaded.
/// - Triggering the loading of the real module when any part of the deferred
///   API is called.
/// - Proxying async API methods: they will wait for the module to load.
/// - Proxying sync API methods: they will only throw if the module has not yet
///   been loaded.
/// - Proxying Events: listeners can be registered immediately.
/// - Proxying components: they will only throw if the module has not yet
///   been loaded.
/// - Proxying of constructors: any constructor defined in the deferred module
///   class that matches a constructor defined in the real module will have
///   bodies generated that store the given arguments and proxy them to the
///   constructors on the real module when it is constructed.
class DeferredModuleTransformer extends AggregateTransformer {
  final BarbackSettings _settings;

  DeferredModuleTransformer.asPlugin(this._settings);

  @override
  classifyPrimary(AssetId id) {
    if (!id.path.endsWith('.dart')) return null;
    return 'w_module_deferred_transformer';
  }

  @override
  apply(AggregateTransform transform) async {
    var deferredModuleTransformer =
        new _DeferredModuleTransformer(_settings, transform);
    await deferredModuleTransformer.done;
  }
}

/// Helper class for applying the deferred module transforms to a single
/// [AggregateTransform] instance. In other words, an instance of this class
/// will be constructed and used each time `WModuleTransformer.apply()` is
/// called.
class _DeferredModuleTransformer {
  /// A pattern that will match any usage of at least one of the following
  /// annotations:
  ///
  ///   * [annotations.DeferrableModule]
  ///   * [annotations.DeferrableModuleApi]
  ///   * [annotations.DeferrableModuleEvents]
  ///   * [annotations.DeferredModule]
  static final RegExp _anyDeferredModuleAnnotation = new RegExp(
      r'@(' +
          [
            _getReflectedName(annotations.DeferrableModule),
            _getReflectedName(annotations.DeferrableModuleApi),
            _getReflectedName(annotations.DeferrableModuleEvents),
            _getReflectedName(annotations.DeferredModule),
          ].join('|') +
          r')',
      caseSensitive: true);

  /// A naive check to determine if an asset's contents might include
  /// annotations relevant to this deferred module transformer.
  ///
  /// This is a naive check because although it will always find legitimate
  /// usages, it may also find false positives (commented out annotation or
  /// the annotation name referenced in documentation, for example).
  static bool _mightContainModuleAnnotations(String contents) =>
      _anyDeferredModuleAnnotation.hasMatch(contents);

  /// Future that resolves when the group of primary inputs from [transform] are
  /// done being analyzed and transformed.
  Future<Null> get done => _done.future;
  Completer _done = new Completer();

  /// Configuration details for the w_module pub transformer.
  final BarbackSettings settings;

  /// The aggregate transform object that provides access to a group of primary
  /// inputs to analyze and potentially transform.
  final AggregateTransform transform;

  List<String> _deferrableModuleNames = [];
  Map<String, NodeWithMeta<ClassDeclaration, annotations.DeferrableModuleApi>>
      _deferrableModuleApiDeclarations = {};
  Map<String,
          NodeWithMeta<ClassDeclaration, annotations.DeferrableModuleEvents>>
      _deferrableModuleEventsDeclarations = {};
  Map<String, NodeWithMeta<ClassDeclaration, annotations.DeferredModule>>
      _deferredModuleDeclarations = {};

  /// Map of source files keyed by the asset's ID.
  Map<AssetId, SourceFile> _sourceFiles = {};

  /// Map of transformed source files keyed by the asset's ID. For every element
  /// in this map, there will be a corresponding source file in [_sourceFiles].
  Map<AssetId, TransformedSourceFile> _transformedSourceFiles = {};

  _DeferredModuleTransformer(
      BarbackSettings this.settings, AggregateTransform this.transform) {
    _done.complete(_apply());
  }

  _apply() async {
    // Iterate over all of the inputs from the [WModuleTransformer], which
    // should be every .dart file.
    await for (Asset asset in transform.primaryInputs) {
      // Read the file as a string and do a naive check to see if it might
      // contain deferred module annotations.
      String assetContents = await asset.readAsString();
      if (_mightContainModuleAnnotations(assetContents)) {
        // Store the source file so that locations or spans from it can be used
        // to make replacements or insertions.
        Uri uri = assetIdToPackageUri(asset.id);
        _sourceFiles[asset.id] = new SourceFile(assetContents, url: uri);

        // Parse this file as a compilation unit so that the AST can be used to
        // get the information needed to apply the deferred module transform.
        CompilationUnit unit = parseCompilationUnit(assetContents,
            suppressErrors: true,
            name: asset.id.path,
            parseFunctionBodies: false);

        // Iterate over the unit looking for declarations annotated with one of
        // the deferred module annotations.
        _deferrableModuleNames.addAll(
            getDeclarationsAnnotatedBy(unit, annotations.DeferrableModule)
                .map((member) =>
                    instantiateAnnotation(member, annotations.DeferrableModule))
                .map((annotation) => annotation.name));
        _deferrableModuleApiDeclarations.addAll(new Map.fromIterable(
            getDeclarationsAnnotatedBy(unit, annotations.DeferrableModuleApi)
                .map((member) => new NodeWithMeta<
                    ClassDeclaration,
                    annotations
                        .DeferrableModuleApi>(member, assetId: asset.id)),
            key: (d) => d.meta.moduleName));
        _deferrableModuleEventsDeclarations.addAll(new Map.fromIterable(
            getDeclarationsAnnotatedBy(unit, annotations.DeferrableModuleEvents)
                .map((member) => new NodeWithMeta<
                    ClassDeclaration,
                    annotations
                        .DeferrableModuleEvents>(member, assetId: asset.id)),
            key: (d) => d.meta.moduleName));
        _deferredModuleDeclarations.addAll(new Map.fromIterable(
            getDeclarationsAnnotatedBy(unit, annotations.DeferredModule).map(
                (member) => new NodeWithMeta<ClassDeclaration,
                    annotations.DeferredModule>(member, assetId: asset.id)),
            key: (d) => d.meta.moduleName));
      }
    }

    // Validate that every module marked as "deferrable" is setup correctly and
    // all required annotations are present.
    _validate();

    // Attempt to transform each deferred module.
    _deferredModuleDeclarations.forEach((moduleName, declaration) {
      var api = _deferrableModuleApiDeclarations[moduleName];
      var events = _deferrableModuleEventsDeclarations[moduleName];
      _transform(moduleName, declaration, api: api, events: events);
    });
  }

  /// It's possible that multiple deferred modules may live in the same file,
  /// so we keep a cache of TransformedSourceFile helpers to ensure that
  /// changes to a source file are kept in one place.
  ///
  /// This assumes that the [SourceFile] for [assetId] is available in
  /// [_sourceFiles].
  TransformedSourceFile _getTransformedSourceFile(AssetId assetId) {
    if (!_transformedSourceFiles.containsKey(assetId)) {
      var sourceFile = _sourceFiles[assetId];
      _transformedSourceFiles[assetId] = new TransformedSourceFile(sourceFile);
    }
    return _transformedSourceFiles[assetId];
  }

  void _transform(
      String moduleName,
      NodeWithMeta<ClassDeclaration,
          annotations.DeferredModule> deferredModuleDeclaration,
      {NodeWithMeta<ClassDeclaration, annotations.DeferrableModuleApi> api,
      NodeWithMeta<ClassDeclaration,
          annotations.DeferrableModuleEvents> events}) {
    // Names of the module-related classes that already exist.
    var deferredModuleClassName = deferredModuleDeclaration.node.name.name;

    // Name of the deferred import in which the real module lives.
    var deferredLibrary = deferredModuleDeclaration.meta.deferredImport;

    // Deferred module class declaration.
    var deferredModuleNode = deferredModuleDeclaration.node;

    // Names for the API, Events, and Mixin classes that will be generated.
    var deferredModuleMixinClassName = '__$deferredModuleClassName' + 'Mixin';
    var deferredApiClassName = '__$deferredModuleClassName' + 'Api';
    var deferredEventsClassName = '__$deferredModuleClassName' + 'Events';

    // General pieces of info about the module setup.
    // TODO: Verify that these getters don't have implementations and are only stubs
    var apiGetter = deferredModuleNode.members.firstWhere(
        (m) => m is MethodDeclaration && m.name.name == 'api',
        orElse: null);
    var componentsGetter = deferredModuleNode.members.firstWhere(
        (m) => m is MethodDeclaration && m.name.name == 'components',
        orElse: null);
    var eventsGetter = deferredModuleNode.members.firstWhere(
        (m) => m is MethodDeclaration && m.name.name == 'events',
        orElse: null);
    var hasApi = apiGetter != null;
    var hasComponents = componentsGetter != null;
    var hasEvents = eventsGetter != null;

    // File helpers.
    var assetId = deferredModuleDeclaration.assetId;
    var sf = _sourceFiles[assetId];
    var tf = _getTransformedSourceFile(assetId);

    // Default constructor (unnamed).
    ConstructorDeclaration defaultCtor = deferredModuleNode.members
        .firstWhere((m) => m is ConstructorDeclaration && m.name == null);
    // Named constructors.
    Iterable<ConstructorDeclaration> namedCtors = deferredModuleNode.members
        .where((m) => m is ConstructorDeclaration && m.name != null);

    // Insert a "GENERATED" banner at the bottom of the file before the
    // generated classes are inserted.
    var generatedBannerBuffer = new StringBuffer()
      ..writeln()
      ..writeln('// ====================')
      ..writeln('// GENERATED CODE BELOW')
      ..writeln('// ====================')
      ..writeln();
    tf.insert(sf.location(sf.length), generatedBannerBuffer.toString());

    // STEP 1:
    // -------
    // Add dart:async import if necessary.

    var unit = deferredModuleNode.parent;
    Iterable<ImportDirective> imports =
        unit.childEntities.where((e) => e is ImportDirective);
    if (imports.where((i) => i.uriContent == 'dart:async').length == 0) {
      tf.insert(sf.location(imports.first.beginToken.offset),
          '/* GENERATED */ import \'dart:async\'; /* END GENERATED */');
    }

    // STEP 2:
    // -------
    // Generate a deferred proxy for the API class.

    if (hasApi) {
      var apiBuffer = new StringBuffer()..writeln();
      var apiTypeName = apiGetter.returnType.name.name;

      var apiDecl = _deferrableModuleApiDeclarations[moduleName];
      if (apiDecl == null) {
        transform.logger.error(
            'The $moduleName module has an Api class but it could not be '
            'found - make sure it is annotated with '
            '@DeferrableModuleApi(\'$moduleName\').');
      } else {
        apiBuffer
          ..writeln('class $deferredApiClassName implements $apiTypeName {')
          ..writeln('  $deferredModuleClassName _deferredModule;')
          ..writeln('  Future<$moduleName> _loaded;')
          ..writeln(
              '  $deferredApiClassName(this._loaded, this._deferredModule);');

        var methods = apiDecl.node.members.where((m) => m is MethodDeclaration);
        methods.forEach((member) {
          if (member is MethodDeclaration) {
            var name = member.name.name;
            if (name.startsWith('_')) return;

            bool isAsync = member.returnType?.name?.name == 'Future';
            var proxy;
            if (isAsync) {
              var argList = [];
              if (member.parameters != null) {
                member.parameters.parameters.forEach((p) {
                  if (p.kind == ParameterKind.NAMED) {
                    argList.add('${p.identifier.name}: ${p.identifier.name}');
                  } else {
                    argList.add('${p.identifier.name}');
                  }
                });
              }
              var args = argList.join(', ');
              proxy = [
                '    if (!_deferredModule._isLoaded) {',
                '      _deferredModule.load();',
                '    }',
                '    var module = await _loaded;',
                '    return module.api.$name($args);'
              ].join('\n');
            } else {
              proxy =
                  '    throw new StateError(\'$moduleName has not yet been loaded.\');';
            }
            apiBuffer.writeln('  ${copyClassMember(member, proxy)}');
          }
        });
      }
      apiBuffer..writeln('}')..writeln();

      tf.replace(getSpanForNode(sf, apiGetter),
          '$apiTypeName get api /* GENERATED */ => _api;');
      tf.insert(sf.location(sf.length), apiBuffer.toString());
    }

    // STEP 3:
    // -------
    // Generate a deferred proxy for the Components class.

    if (hasComponents) {
      StringBuffer sb = new StringBuffer()
        ..write('${componentsGetter.returnType.name.name} get components { ')
        ..write('/* GENERATED */ ')
        ..write('_verifyIsLoaded(); ')
        ..write('return _actual.components; ')
        ..write('}');

      tf.replace(getSpanForNode(sf, componentsGetter), sb.toString());
    }

    // STEP 4:
    // -------
    // Generate a deferred proxy for the Events class.

    if (hasEvents) {
      var eventsBuffer = new StringBuffer()..writeln();
      var eventsTypeName = eventsGetter.returnType.name.name;

      var eventsDecl = _deferrableModuleEventsDeclarations[moduleName];
      if (eventsDecl == null) {
        transform.logger.error(
            'The $moduleName module has an Events class but it could not be '
            'found - make sure it is annotated with '
            '@DeferrableModuleEvents(\'$moduleName\').');
      } else {
        var dispatchKeyName = '_dispatchKey$deferredEventsClassName';
        eventsBuffer
          ..writeln(
              'DispatchKey $dispatchKeyName = new DispatchKey(\'$deferredEventsClassName\');')
          ..writeln(
              'class $deferredEventsClassName implements $eventsTypeName {')
          ..writeln('  Future _loaded;');

        Iterable<FieldDeclaration> streams =
            eventsDecl.node.members.where((f) => f is FieldDeclaration);
        streams.forEach((stream) {
          var name = stream.fields.variables.first.name.name;
          var type = stream.fields.type;
          eventsBuffer
            ..writeln('  final $type $name = new $type($dispatchKeyName);');
        });

        eventsBuffer
          ..writeln('  $deferredEventsClassName(this._loaded) {')
          ..writeln('    _loaded.then((module) {');
        streams.forEach((stream) {
          var name = stream.fields.variables.first.name.name;
          eventsBuffer
            ..writeln('      module.events.$name.listen((event) {')
            ..writeln('        $name(event, $dispatchKeyName);')
            ..writeln('      });');
        });
        eventsBuffer
          ..writeln('    });')
          ..writeln('  }')
          ..writeln('}')
          ..writeln();
      }

      tf.replace(getSpanForNode(sf, eventsGetter),
          '$eventsTypeName get events /* GENERATED */ => _events;');
      tf.insert(sf.location(sf.length), eventsBuffer.toString());
    }

    // Step 5:
    // -------
    // Generate a mixin for the deferred module implementation.

    List<String> generatedVars = [
      '_actual',
      '_api',
      '_constructorCalled',
      '_events',
      '_isLoaded',
      '_loaded',
    ];

    StringBuffer mixinBuffer = new StringBuffer()
      ..writeln()
      ..writeln('abstract class $deferredModuleMixinClassName {')
      ..writeln('  _init() {')
      ..writeln('    _isLoaded = false;')
      ..writeln('    _loaded = new Completer();')
      ..writeln('    _api = new $deferredApiClassName(_loaded.future, this);')
      ..writeln('    _events = new $deferredEventsClassName(_loaded.future);')
      ..writeln('  }');

    // TODO: Verify that these constructors don't have initializers or bodies and are only stubs!!!

    if (defaultCtor == null && namedCtors.isEmpty) {
      // No constructors defined, so define an empty default constructor.
      var defaultCtorStr = '$deferredModuleClassName() { '
          '/* GENERATED */ '
          '_init(); '
          '_constructorCalled = \'\'; '
          '}';

      mixinBuffer
        ..writeln('  _construct() {')
        ..writeln('    _actual = new $deferredLibrary.$moduleName();')
        ..writeln('  }');

      tf.replace(getSpanForNode(sf, defaultCtor), defaultCtorStr.toString());
    } else {
      if (defaultCtor != null) {
        var ctorVarPrefix = '_${deferredModuleClassName}_';
        StringBuffer defaultCtorBuffer = new StringBuffer();
        defaultCtor.parameters.parameters.forEach((param) {
          generatedVars.add('$ctorVarPrefix${param.identifier.name}');
        });

        var ctorParams = defaultCtor.parameters.toString();
        defaultCtorBuffer
          ..write('$deferredModuleClassName$ctorParams { ')
          ..write('/* GENERATED */ ')
          ..write('_init(); ')
          ..write('_constructorCalled = \'\'; ');

        defaultCtor.parameters.parameters.forEach((param) {
          defaultCtorBuffer.write(
              '$ctorVarPrefix${param.identifier.name} = ${param.identifier.name}; ');
        });

        defaultCtorBuffer.write('}');

        var argList = [];
        defaultCtor.parameters.parameters.forEach((p) {
          if (p.kind == ParameterKind.NAMED) {
            argList.add(
                '${p.identifier.name}: $ctorVarPrefix${p.identifier.name}');
          } else {
            argList.add('$ctorVarPrefix${p.identifier.name}');
          }
        });
        var args = argList.join(', ');
        mixinBuffer
          ..writeln()
          ..writeln('  _construct() {')
          ..writeln('    _actual = new $deferredLibrary.$moduleName($args);')
          ..writeln('  }');

        tf.replace(
            getSpanForNode(sf, defaultCtor), defaultCtorBuffer.toString());
      }

      if (namedCtors.isNotEmpty) {
        namedCtors.forEach((ctor) {
          var ctorVarPrefix = '_${deferredModuleClassName}_${ctor.name.name}_';
          StringBuffer ctorBuffer = new StringBuffer();
          ctor.parameters.parameters.forEach((param) {
            generatedVars.add('$ctorVarPrefix${param.identifier.name}');
          });

          var ctorParams = ctor.parameters.toString();
          ctorBuffer
            ..write('$deferredModuleClassName.${ctor.name.name}$ctorParams { ')
            ..write('/* GENERATED */ ')
            ..write('_init(); ')
            ..write('_constructorCalled = \'${ctor.name.name}\'; ');

          ctor.parameters.parameters.forEach((param) {
            ctorBuffer.write(
                '$ctorVarPrefix${param.identifier.name} = ${param.identifier.name}; ');
          });

          ctorBuffer.write('}');

          var argList = [];
          defaultCtor.parameters.parameters.forEach((p) {
            if (p.kind == ParameterKind.NAMED) {
              argList.add(
                  '${p.identifier.name}: $ctorVarPrefix${p.identifier.name}');
            } else {
              argList.add('$ctorVarPrefix${p.identifier.name}');
            }
          });
          var args = argList.join(', ');
          mixinBuffer
            ..writeln()
            ..writeln('  _construct${ctor.name.name}() {')
            ..writeln(
                '    _actual = new $deferredLibrary.$moduleName.${ctor.name.name}($args);')
            ..writeln('  }');

          tf.replace(getSpanForNode(sf, ctor), ctorBuffer.toString());
        });
      }
    }

    var generatedVarsStr = '/* GENERATED */ var ${generatedVars.join(', ')};';
    tf.insert(
        sf.location(deferredModuleNode.leftBracket.end), generatedVarsStr);

    mixinBuffer
      ..writeln()
      ..writeln('  _constructActualModule() {')
      ..writeln('    if (_constructorCalled == \'\') {')
      ..writeln('      _construct();')
      ..writeln('    }');

    if (namedCtors.isNotEmpty) {
      namedCtors.forEach((ctor) {
        mixinBuffer
          ..writeln('    if (_constructorCalled == \'${ctor.name.name}\') {')
          ..writeln('      _construct${ctor.name.name}();')
          ..writeln('    }');
      });
    }

    mixinBuffer.writeln('  }');

    mixinBuffer
      ..writeln()
      ..writeln('  @override')
      ..writeln('  onLoad() async {')
      ..writeln('    if (_isLoaded) return;')
      ..writeln('    await $deferredLibrary.loadLibrary();')
      ..writeln('    if (_isLoaded) return;')
      ..writeln('    _constructActualModule();')
      ..writeln('    _isLoaded = true;')
      ..writeln('    _loaded.complete(_actual);')
      ..writeln('  }')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  onUnload() {')
      ..writeln('    _verifyIsLoaded();')
      ..writeln('    return _actual.shouldUnload();')
      ..writeln('  }')
      ..writeln()
      ..writeln('  void _verifyIsLoaded() {')
      ..writeln('    if (!_isLoaded) throw new StateError(')
      ..writeln(
          '        \'Cannot access deferred module until it has been loaded.\');')
      ..writeln('  }')
      ..writeln();

    for (var generatedVar in generatedVars) {
      mixinBuffer..writeln('  get $generatedVar; set $generatedVar(v);');
    }

    mixinBuffer..writeln('}')..writeln();

    tf.insert(sf.location(sf.length), mixinBuffer.toString());

    // Step 6:
    // -------
    // Transform the deferred module class to use the generated mixin.

    if (deferredModuleNode.extendsClause == null) {
      // No extends clause, no with clause.
      var extendsWithClause =
          'extends Object with $deferredModuleMixinClassName';
      if (deferredModuleNode.implementsClause != null) {
        // Has implements clause, so insert right before it.
        tf.insert(sf.location(deferredModuleNode.implementsClause.offset),
            extendsWithClause);
      } else {
        // No implements clause, so insert right before left bracket.
        tf.insert(sf.location(deferredModuleNode.leftBracket.offset),
            extendsWithClause);
      }
    } else if (deferredModuleNode.withClause == null) {
      // Has extends clause, but no with clause, so insert after extends.
      tf.insert(sf.location(deferredModuleNode.extendsClause.end),
          ' with $deferredModuleMixinClassName');
    } else {
      // Has extends clause and with clause, so add to the with clause.
      tf.insert(sf.location(deferredModuleNode.withClause.end),
          ', $deferredModuleMixinClassName');
    }

    // Step 7:
    // -------
    // Add the transformed output.

    if (tf.isModified) {
      transform
          .addOutput(new Asset.fromString(assetId, tf.getTransformedText()));
    }

    if (settings.mode == BarbackMode.DEBUG) {
      transform.addOutput(new Asset.fromString(
          assetId.addExtension('.diff.html'), tf.getHtmlDiff()));
    }
  }

  void _validate() {
    // Warn about modules marked as "deferrable" with no corresponding deferred
    // module class.
    for (String moduleName in _deferrableModuleNames) {
      if (!_deferredModuleDeclarations.containsKey(moduleName)) {
        transform.logger.error(
            '@DeferrableModule annotation expects a class with a correlating '
            '@DeferredModule annotation, but one was not found.');
      }
    }

    // Warn about modules marked as "deferred" with no corresponding real module
    // class.
    for (String moduleName in _deferredModuleDeclarations.keys) {
      if (!_deferrableModuleNames.contains(moduleName)) {
        transform.logger.error(
            '@DeferredModule annotation expects a $moduleName class with a '
            'correlating @DeferrableModule annotation, but one was not found.');
      }
    }

    // TODO: warn about deferred modules with API but missing API annotation
    // TODO: warn about deferred modules with Events but missing Events annotation
  }
}
