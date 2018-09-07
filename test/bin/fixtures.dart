import 'dart:io';

import 'package:test/test.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart'; // ignore: implementation_imports
import 'package:w_module/src/bin/analyzer_tools.dart';

const String tempDirPath = 'test_fixtures/test_temp';
const String inputDirPath = 'test_fixtures/test_input';
const String expectedOutputDirPath = 'test_fixtures/test_expected';

Map<Source, List<ClassElement>> _modulesWithoutNames;

Map<Source, List<ClassElement>> get modulesWithoutNames {
  if (_modulesWithoutNames != null) {
    return _modulesWithoutNames;
  }

  Directory packageDir = new Directory(tempDirPath);

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

void createTempDir() {
  copyDirCommand(inputDirPath, tempDirPath);
}

void clearTempDir() {
  final directory = new Directory(tempDirPath);
  if (directory.existsSync()) {
    directory.deleteSync(recursive: true);
  }
}

void copyDirCommand(String from, String to) {
  // because doing this in dart is ~30 lines
  Process.runSync('cp', ['-r', from, to]);
}

String fileNameFromPath(String path) => path.split('/').last;
