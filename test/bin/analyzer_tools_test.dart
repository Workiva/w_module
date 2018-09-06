import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('AnalyzerTools', () {
    modulesWithoutNames.forEach((source, classes) {
      print(source.shortName);
      print(classes.map((e) => '  ${e.name}').join('\n'));
      print('}\n');
    });

    const String accessorsName = 'accessors.dart';
    group(accessorsName, () {
      List<ClassElement> classes;

      setUp(() {
        classes = modulesForSourceName(accessorsName);
      });

      test('catches setter-only `name`', () {
        expect(findClassByName(classes, 'ModuleWithNameSetter'), isNotNull);
      });

      <
          String>[
        'ModuleWithNameGetter',
        'ModuleWithNameGetterSetter',
        'ModuleWithNameField',
        'ModuleWithFinalNameField',
      ].forEach((className) {
        test('does not catch $className', () {
          expect(
              () => findClassByName(classes, className), throwsA(isException));
        });
      });
    });

    const String inheritanceName = 'inheritance.dart';
    group(inheritanceName, () {
      List<ClassElement> classes;

      setUp(() {
        classes = modulesForSourceName(inheritanceName);
      });

      <
          String>[
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

      <
          String>[
        'NamedModule',
        'NamedModuleExtendsFromNamedModule',
        'NamedModuleExtendsFromUnnamedModule',
        'NamedUnnamedUnnamed',
        'NamedUnnamedNamed',
        'NamedNamedUnnamed',
        'NamedNamedNamed',
      ].forEach((className) {
        test('does not catch $className', () {
          expect(
              () => findClassByName(classes, className), throwsA(isException));
        });
      });
    });
  });
}
