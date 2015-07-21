library w_module.src.deferred_module_generator;

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart' show ParameterKind;
import 'package:source_gen/source_gen.dart';

import 'package:w_module/src/deferred_module.dart' show DeferredModule;
import 'package:w_module/src/module.dart' show Module;

class DeferredModuleGenerator extends GeneratorForAnnotation<DeferredModule> {
  const DeferredModuleGenerator();

  generateForAnnotatedElement(LibraryElement element, DeferredModule annotation) {
    Class apiClass = _getClass(element, annotation.apiClass);
    Class componentsClass = _getClass(element, annotation.componentsClass);
    Class eventsClass = _getClass(element, annotation.eventsClass);
    Class moduleClass = _getClass(element, annotation.moduleClass);

    StringBuffer buffer = new StringBuffer();

    String apiClassDef = _generateAbstractClass(apiClass.element);
    String componentsClassDef = _generateAbstractClass(componentsClass.element);
    String eventsClassDef = _generateAbstractClass(eventsClass.element);

    buffer.writeln(apiClassDef);
    buffer.writeln(componentsClassDef);
    buffer.writeln(eventsClassDef);

    buffer.writeln('');

    buffer.writeln('class Deferred${moduleClass.element.name} extends Module {');

    buffer.writeln('  String get name {');
    buffer.writeln('    if (!_isLoaded) return \'Deferred${moduleClass.element.name}\';');
    buffer.writeln('    return _actual.name;');
    buffer.writeln('  }');

    buffer.writeln('');

    buffer.writeln('  var _actual;');
    buffer.writeln('  bool _isLoaded = false;');

    buffer.writeln('');

    buffer.writeln('  ${apiClass.element.name} get api {');
    buffer.writeln('    _verifyIsLoaded();');
    buffer.writeln('    return _actual.api;');
    buffer.writeln('  }');

    buffer.writeln('');

    buffer.writeln('  ${componentsClass.element.name} get components {');
    buffer.writeln('    _verifyIsLoaded();');
    buffer.writeln('    return _actual.components;');
    buffer.writeln('  }');

    buffer.writeln('');

    buffer.writeln('  ${eventsClass.element.name} get events {');
    buffer.writeln('    _verifyIsLoaded();');
    buffer.writeln('    return _actual.events;');
    buffer.writeln('  }');

    buffer.writeln('');

    buffer.writeln('  Future onLoad() async {');
    buffer.writeln('    await ${moduleClass.libraryPrefix}.loadLibrary();');
    buffer.writeln('    _actual = new ${moduleClass.libraryPrefix}.${moduleClass.element.name}();');
    buffer.writeln('    _isLoaded = true;');
    buffer.writeln('  }');

    buffer.writeln('');

    buffer.writeln('  Future<bool> shouldUnload() {');
    buffer.writeln('    _verifyIsLoaded();');
    buffer.writeln('    return _actual.shouldUnload();');
    buffer.writeln('  }');

    buffer.writeln('');

    buffer.writeln('  Future onUnload() {');
    buffer.writeln('    _verifyIsLoaded();');
    buffer.writeln('    return _actual.onUnload();');
    buffer.writeln('  }');

    buffer.writeln('');

    buffer.writeln('  void _verifyIsLoaded() {');
    buffer.writeln('    if (!_isLoaded)');
    buffer.writeln('      throw new StateError(\'Cannot access deferred module\\\'s API until it has been loaded.\');');
    buffer.writeln('  }');

    buffer.writeln('}');
    return buffer.toString();
  }

  String _generateAbstractClass(ClassElement element) {
    StringBuffer buffer = new StringBuffer();
    buffer.writeln('abstract class ${element.name} {');

    print(element.name);
    print(element.fields);
    print(element.accessors);
    print(element.methods);
    print('\n');

    element.fields.forEach((FieldElement f) {
      if (f.isPrivate || f.isStatic) return;

      String field = '${f.name};';
      if (f.isFinal) {
        // Final fields don't work in an abstract class.
        // Use an abstract getter instead.
        field = 'get $field';
      }
      if (f.type != null) {
        field = '${f.type.name} $field';
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
          accessor = '${a.type.name} $accessor';
        }
      } else {
        accessor = 'set $accessor';
        ParameterElement param = a.parameters.first;
        String paramStr = '${param.name}';
        if (param.type != null) {
          paramStr = '${param.type.name} $paramStr';
        }
        accessor = '$accessor($paramStr)';
      }
      accessor = '$accessor;';
    });

    element.methods.forEach((MethodElement m) {
      if (m.isPrivate || m.isStatic) return;

      String method = '${m.name}';
      if (m.returnType != null) {
        method = '${m.returnType.name} $method';
      }

      String params = '';

      void appendParam(String name, {DartType type, dynamic defaultValue, bool positional: false}) {
        if (type != null) {
          params = '$params${type.name} ';
        }
        params = '$params$name';
      }

      bool firstPositionalReached = false;
      bool firstNamedReached = false;
      m.type.parameters.forEach((p) {
        if (!params.isEmpty) {
          // Separate param from previous with comma.
          params = '$params, ';
        }

        if (p.parameterKind == ParameterKind.REQUIRED) {
          appendParam(p.name, type: p.type);
        } else if (p.parameterKind == ParameterKind.POSITIONAL) {
          if (!firstPositionalReached) {
            // Add the bracket to enclose positional params.
            params = '$params[';
            firstPositionalReached = true;
          }
          appendParam(p.name, type: p.type);
        } else if (p.parameterKind == ParameterKind.NAMED) {
          if (!firstNamedReached) {
            // Add the brace to enclose named params.
            params = '$params{';
            firstNamedReached = true;
          }
          appendParam(p.name, type: p.type);
        }
      });

      // Close the optional/named brackets if necessary.
      if (firstPositionalReached) {
        params = '$params]';
      }
      if (firstNamedReached) {
        params = '$params}';
      }

      method = '$method($params);';
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

    LibraryElement targetLibrary;
    ClassElement targetClass;
    if (libraryPrefix != null) {
      for (int i = 0; i < currentLibrary.importedLibraries.length; i++) {
        targetLibrary = currentLibrary.importedLibraries[i];
        targetClass = _findClassInLibrary(targetLibrary, className);
        if (targetClass != null) break;
      }
    }

    if (targetClass == null) {
      throw new InvalidGenerationSourceError('DeferredModuleGenerator: Could not find the targeted class: $location');
    }

    return new Class(targetClass, libraryPrefix);
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
  final String libraryPrefix;
  Class(ClassElement this.element, [String libraryPrefix])
      : hasLibraryPrefix = libraryPrefix != null,
        this.libraryPrefix = libraryPrefix;
}