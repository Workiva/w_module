import 'dart:io';

import 'package:analyzer/dart/element/element.dart';

const String tempDirPath = 'test_fixtures/test_temp';
const String inputDirPath = 'test_fixtures/test_input';
const String expectedOutputDirPath = 'test_fixtures/test_expected';


ClassElement findClassByName(List<ClassElement> classes, String name) {
  for (ClassElement element in classes) {
    if (element.name == name) {
      return element;
    }
  }

  throw new Exception('Class not found: $name');
}

// because doing this in dart is ~30 lines
void createTempDir() => Process.run('cp', ['-r', inputDirPath, tempDirPath]);

void clearTempDir() {
  final directory = new Directory(tempDirPath);
  if (directory.existsSync()) {
    return directory.deleteSync(recursive: true);
  }
}

String fileNameFromPath(String path) => path.split('/').last;
