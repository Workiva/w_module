import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart'; // ignore: implementation_imports
import 'package:w_module/src/bin/analyzer_tools.dart';

const String everythingPackageDir = 'test_fixtures/everything';

Map<Source, List<ClassElement>> _modulesWithoutNames;

Map<Source, List<ClassElement>> get modulesWithoutNames {
  if (_modulesWithoutNames != null) {
    return _modulesWithoutNames;
  }

  Directory packageDir = new Directory(everythingPackageDir);

  _modulesWithoutNames = getModulesWithoutNamesBySource(packageDir: packageDir);
  return _modulesWithoutNames;
}

List<ClassElement> modulesForSourceName(String sourceName) {
  final key = modulesWithoutNames.keys
      .firstWhere((source) => source.shortName == sourceName);

  assert(key != null, '$sourceName not found. This is a human error.');

  return modulesWithoutNames[key];
}

ClassElement findClassByName(List<ClassElement> classes, String name) {
  for (ClassElement element in classes) {
    if (element.name == name) {
      return element;
    }
  }

  throw new Exception('Class not found: $name');
}
