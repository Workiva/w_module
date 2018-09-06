import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
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
          expect(
              () => findClassByName(classes, className), throwsA(isException));
        });
      });
    });
  });
}
