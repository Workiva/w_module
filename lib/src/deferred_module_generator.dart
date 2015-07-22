library w_module.src.deferred_module_generator;

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart' show ParameterKind;
import 'package:source_gen/source_gen.dart';

import 'package:w_module/src/deferred_module.dart' show DeferredModule;
import 'package:w_module/src/module.dart' show Module;

String _getFullType(DartType type) {
  String typeStr = '${type.name}';
  if (type is ParameterizedType) {
    if (type.typeArguments.isNotEmpty) {
      typeStr = '$typeStr<${type.typeArguments.join(', ')}>';
    }
  }
  return typeStr;
}

String _getFullParameters(List<ParameterElement> parameters) {
  String paramStr = '';

  void appendParam(String name, {DartType type, dynamic defaultValue, bool positional: false}) {
    if (type != null) {
      paramStr = '$paramStr${_getFullType(type)} ';
    }
    paramStr = '$paramStr$name';
  }

  bool firstPositionalReached = false;
  bool firstNamedReached = false;

  parameters.forEach((p) {
    if (!paramStr.isEmpty) {
      // Separate param from previous with comma.
      paramStr = '$paramStr, ';
    }

    if (p.parameterKind == ParameterKind.REQUIRED) {
      appendParam(p.name, type: p.type);
    } else if (p.parameterKind == ParameterKind.POSITIONAL) {
      if (!firstPositionalReached) {
        // Add the bracket to enclose positional params.
        paramStr = '$paramStr[';
        firstPositionalReached = true;
      }
      appendParam(p.name, type: p.type);
    } else if (p.parameterKind == ParameterKind.NAMED) {
      if (!firstNamedReached) {
        // Add the brace to enclose named params.
        paramStr = '$paramStr{';
        firstNamedReached = true;
      }
      appendParam(p.name, type: p.type);
    }
  });

  // Close the optional/named brackets if necessary.
  if (firstPositionalReached) {
    paramStr = '$paramStr]';
  }
  if (firstNamedReached) {
    paramStr = '$paramStr}';
  }

  return paramStr;
}

class DeferredModuleGenerator extends GeneratorForAnnotation<DeferredModule> {
  const DeferredModuleGenerator();

  generateForAnnotatedElement(LibraryElement element, DeferredModule annotation) {
    StringBuffer buffer = new StringBuffer();

    Class apiClass;
    if (annotation.apiClass != null) {
      apiClass = _getClass(element, annotation.apiClass);
      String apiClassDef = _generateAbstractClass(apiClass.element);
      buffer.writeln('');
      buffer.writeln(apiClassDef);
    }

    Class componentsClass;
    if (annotation.componentsClass != null) {
      componentsClass = _getClass(element, annotation.componentsClass);
      String componentsClassDef = _generateAbstractClass(componentsClass.element, superClass: 'ModuleComponents');
      buffer.writeln('');
      buffer.writeln(componentsClassDef);
    }

    Class eventsClass;
    if (annotation.eventsClass != null) {
      eventsClass = _getClass(element, annotation.eventsClass);
      String eventsClassDef = _generateAbstractClass(eventsClass.element);
      buffer.writeln('');
      buffer.writeln(eventsClassDef);
    }

    Class moduleClass = _getClass(element, annotation.moduleClass);

    Set<String> deferredLoads = new Set();
    if (apiClass != null && apiClass.isDeferred) {
      deferredLoads.add(apiClass.libraryPrefix);
    }
    if (componentsClass != null && componentsClass.isDeferred) {
      deferredLoads.add(componentsClass.libraryPrefix);
    }
    if (eventsClass != null && eventsClass.isDeferred) {
      deferredLoads.add(eventsClass.libraryPrefix);
    }
    if (moduleClass != null && moduleClass.isDeferred) {
      deferredLoads.add(moduleClass.libraryPrefix);
    }

    Map<ConstructorElement, Constructor> ctors = {};
    moduleClass.element.constructors.forEach((c) {
      ctors[c] = new Constructor(c);
    });

    /// Deferred module class.
    buffer.writeln('');
    buffer.writeln('class Deferred${moduleClass.element.name} extends Module {');

    buffer.writeln('  String get name {');
    buffer.writeln('    if (!_isLoaded) return \'Deferred${moduleClass.element.name}\';');
    buffer.writeln('    return _actual.name;');
    buffer.writeln('  }');

    buffer.writeln('');

    buffer.writeln('  var _actual;');
    buffer.writeln('  String _constructorCalled;');
    buffer.writeln('  bool _isLoaded = false;');

    /// Module API.
    if (apiClass != null) {
      buffer.writeln('');
      buffer.writeln('  @override');
      buffer.writeln('  ${apiClass.element.name} get api {');
      buffer.writeln('    _verifyIsLoaded();');
      buffer.writeln('    return _actual.api;');
      buffer.writeln('  }');
    }

    /// Module components.
    if (componentsClass != null) {
      buffer.writeln('');
      buffer.writeln('  @override');
      buffer.writeln('  ${componentsClass.element.name} get components {');
      buffer.writeln('    _verifyIsLoaded();');
      buffer.writeln('    return _actual.components;');
      buffer.writeln('  }');
    }

    /// Module events.
    if (eventsClass != null) {
      buffer.writeln('');
      buffer.writeln('  @override');
      buffer.writeln('  ${eventsClass.element.name} get events {');
      buffer.writeln('    _verifyIsLoaded();');
      buffer.writeln('    return _actual.events;');
      buffer.writeln('  }');
    }

    /// Module constructors.
    moduleClass.element.constructors.forEach((c) {
      buffer.writeln('');
      c.parameters.forEach((p) {
        buffer.writeln('var ${ctors[c].varFor(p)};');
      });

      buffer.writeln('');
      buffer.writeln('  ${ctors[c].deferredName}(${_getFullParameters(c.parameters)}) {');
      buffer.writeln('    _constructorCalled = \'${c.name}\';');
      c.parameters.forEach((p) {
        buffer.writeln('${ctors[c].varFor(p)} = ${p.name};');
      });
      buffer.writeln('  }');
    });

    /// Module lifecycle.
    buffer.writeln('');
    buffer.writeln('  Future onLoad() async {');
    buffer.writeln('    await Future.wait([');
    deferredLoads.forEach((d) {
      buffer.writeln('        $d.loadLibrary(),');
    });
    buffer.writeln('    ]);');
    buffer.writeln('    _constructActualModule();');
    buffer.writeln('    _isLoaded = true;');
    buffer.writeln('  }');

    buffer.writeln('');
    buffer.writeln('  ShouldUnloadResult shouldUnload() {');
    buffer.writeln('    _verifyIsLoaded();');
    buffer.writeln('    return _actual.shouldUnload();');
    buffer.writeln('  }');

    buffer.writeln('');
    buffer.writeln('  Future onUnload() {');
    buffer.writeln('    _verifyIsLoaded();');
    buffer.writeln('    return _actual.onUnload();');
    buffer.writeln('  }');

    buffer.writeln('');
    buffer.writeln('  void _constructActualModule() {');
    moduleClass.element.constructors.forEach((c) {
      buffer.writeln('    if (_constructorCalled == \'${c.name}\') {');
      String ctorLoc = '';
      if (moduleClass.hasLibraryPrefix) {
        ctorLoc = '${moduleClass.libraryPrefix}.';
      }
      ctorLoc = '$ctorLoc${ctors[c].name}';
      buffer.writeln('      _actual = new $ctorLoc(${ctors[c].fillArgs()});');
      buffer.writeln('    }');
    });
    buffer.writeln('  }');

    buffer.writeln('');
    buffer.writeln('  void _verifyIsLoaded() {');
    buffer.writeln('    if (!_isLoaded)');
    buffer.writeln('      throw new StateError(\'Cannot access deferred module\\\'s API until it has been loaded.\');');
    buffer.writeln('  }');

    buffer.writeln('}');
    return buffer.toString();
  }

  String _generateAbstractClass(ClassElement element, {String superClass}) {
    StringBuffer buffer = new StringBuffer();
    String extendsClause = superClass != null ? 'extends $superClass' : '';
    buffer.writeln('abstract class ${element.name} $extendsClause {');

    element.fields.forEach((FieldElement f) {
      if (f.isPrivate || f.isStatic) return;

      String field = '${f.name};';
      if (f.isFinal) {
        // Final fields don't work in an abstract class.
        // Use an abstract getter instead.
        field = 'get $field';
      }
      if (f.type != null) {
        field = '${_getFullType(f.type)} $field';
      } else if (!f.isFinal) {
        // Untyped, non-final must use `var`.
        field = 'var $field';
      }

      buffer.writeln(field);
    });

    element.accessors.forEach((PropertyAccessorElement a) {
      if (a.isPrivate || a.isStatic) return;

      String accessor = '${a.name}';
      if (a.isGetter) {
        accessor = 'get $accessor';
        if (a.type != null) {
          accessor = '${_getFullType(a.type)} $accessor';
        }
      } else {
        accessor = 'set $accessor';
        ParameterElement param = a.parameters.first;
        String paramStr = '${param.name}';
        if (param.type != null) {
          paramStr = '${_getFullType(param.type)} $paramStr';
        }
        accessor = '$accessor($paramStr)';
      }
      accessor = '$accessor;';
    });

    element.methods.forEach((MethodElement m) {
      if (m.isPrivate || m.isStatic) return;

      String method = '${m.name}';
      if (m.returnType != null) {
        method = '${_getFullType(m.returnType)} $method';
      }

      method = '$method(${_getFullParameters(m.type.parameters)});';
      buffer.writeln(method);
    });

    buffer.writeln('}');

    return buffer.toString();
  }

  Class _getClass(LibraryElement currentLibrary, String location) {
    var parts = location.split('.');
    String libraryPrefix;
    String className;
    if (parts.length == 2) {
      libraryPrefix = parts[0];
      className = parts[1];
    } else if (parts.length == 1) {
      className = parts[0];
    } else {
      throw new ArgumentError('DeferredModuleGenerator: Invalid class location: $location');
    }

    ImportElement targetImport;
    LibraryElement targetLibrary;
    ClassElement targetClass;
    for (int i = 0; i < currentLibrary.imports.length; i++) {
      targetImport = currentLibrary.imports[i];
      targetLibrary = targetImport.importedLibrary;
      targetClass = _findClassInLibrary(targetLibrary, className);
      if (targetClass != null) break;
    }

    if (targetClass == null) {
      throw new InvalidGenerationSourceError('DeferredModuleGenerator: Could not find the targeted class: $location');
    }

    return new Class(targetClass, isDeferred: targetImport.isDeferred, libraryPrefix: libraryPrefix);
  }

  ClassElement _findClassInLibrary(LibraryElement element, String className) {
    ClassElement targetClass;
    for (int i = 0; i < element.visibleLibraries.length; i++) {
      targetClass = element.visibleLibraries[i].getType(className);
      if (targetClass != null) break;
    }
    return targetClass;
  }
}

class Class {
  final ClassElement element;
  final bool hasLibraryPrefix;
  final bool isDeferred;
  final String libraryPrefix;
  Class(ClassElement this.element, {bool this.isDeferred: false, String libraryPrefix})
      : hasLibraryPrefix = libraryPrefix != null,
        this.libraryPrefix = libraryPrefix;
}

class Constructor {
  ConstructorElement element;

  String get deferredName => 'Deferred$name';

  String get name {
    String n = element.enclosingElement.name;
    if (element.name.isNotEmpty) {
      n = '$n.${element.name}';
    }
    return n;
  }

  Constructor(ConstructorElement this.element);

  String fillArgs() {
    List a = [];
    element.parameters.forEach((p) {
      if (p.parameterKind == ParameterKind.NAMED) {
        a.add('${p.name}: ${varFor(p)}');
      } else {
        a.add(varFor(p));
      }
    });
    return a.join(', ');
  }

  String varFor(ParameterElement param) => '_${name.replaceAll('.', '_')}_${param.name}';
}