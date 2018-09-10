import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart'; // ignore: implementation_imports
import 'package:test/test.dart';

import 'package:w_module/src/bin/utils.dart';
import 'package:w_module/src/bin/analyzer_tools.dart';

import 'fixtures.dart';

void main() {
  group('name_upgrader', () {
    final Directory packageDir = new Directory(tempDirPath);
    Map<Source, List<ClassElement>> modulesWithoutNames;

    List<ClassElement> modulesForSourceName(String sourceName) {
      final key = modulesWithoutNames.keys
          .firstWhere((source) => source.shortName == sourceName);

      assert(key != null, '$sourceName not found. This is a human error.');

      return modulesWithoutNames[key];
    }

    setUp(() {
      createTempDir();
      modulesWithoutNames = getModulesWithoutNamesBySource(packageDir: packageDir);
    });

    tearDown(() {
      modulesWithoutNames.clear();
      clearTempDir();
    });

    group('AnalyzerTools', () {
      const String accessorsName = 'accessors.dart';

      group(accessorsName, () {
        List<ClassElement> classes;

        setUp(() {
          classes = modulesForSourceName(accessorsName);
        });

        [
          'ModuleWithNameSetter',
        ].forEach((className) {
          test('catches $className', () {
            expect(findClassByName(classes, className), isNotNull);
          });
        });

        [
          'ModuleWithNameGetter',
          'ModuleWithNameGetterSetter',
          'ModuleWithNameField',
          'ModuleWithFinalNameField',
        ].forEach((className) {
          test('does not catch $className', () {
            expect(() => findClassByName(classes, className),
                throwsA(isException));
          });
        });
      });

      const String inheritanceName = 'inheritance.dart';
      group(inheritanceName, () {
        List<ClassElement> classes;

        setUp(() {
          classes = modulesForSourceName(inheritanceName);
        });

        [
          'UnnamedModule',
          'UnnamedModuleExtendsFromNamedModule',
          'UnnamedModuleExtendsFromUnnamedModule',
          'UnnamedUnnamedUnnamed',
          'UnnamedUnnamedNamed',
          'UnnamedNamedUnnamed',
          'UnnamedNamedNamed',
        ].forEach((className) {
          test('catches $className', () {
            expect(findClassByName(classes, className), isNotNull);
          });
        });

        [
          'NamedModule',
          'NamedModuleExtendsFromNamedModule',
          'NamedModuleExtendsFromUnnamedModule',
          'NamedUnnamedUnnamed',
          'NamedUnnamedNamed',
          'NamedNamedUnnamed',
          'NamedNamedNamed',
        ].forEach((className) {
          test('does not catch $className', () {
            expect(() => findClassByName(classes, className),
                throwsA(isException));
          });
        });
      });
    });

    test('files are updated to match expected test_output', () {
      modulesWithoutNames.forEach(writeGettersForSource);

      final Directory temp = new Directory('$tempDirPath/lib');

      expect(temp.existsSync(), isTrue);

      final List<FileSystemEntity> tempFiles =
          temp.listSync(recursive: true, followLinks: false);

      final Directory expected = new Directory('$expectedOutputDirPath/lib');
      expect(expected.exists(), isTrue);

      final List<FileSystemEntity> expectedFiles =
          expected.listSync(recursive: true, followLinks: false);

      expect(tempFiles.length, expectedFiles.length);

      File tempFile, expectedFile;
      String tempContents, expectedContents;
      tempFiles
        .where((entity) => entity is File)
        .forEach((entity) {
        tempFile = entity;
        expectedFile = expectedFiles.firstWhere((entity) =>
            fileNameFromPath(entity.path) == fileNameFromPath(tempFile.path));

        tempContents = tempFile.readAsStringSync();
        expectedContents = expectedFile.readAsStringSync();

        expect(tempContents, expectedContents);
      });
    });
  });
}
