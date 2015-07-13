library w_module.test.lifecycle_module_test;

import 'package:w_module/w_module.dart';
import 'package:test/test.dart';

class TestModule extends Module {}

void main() {
  group('Module', () {
    TestModule module;

    setUp(() {
      module = new TestModule();
    });

    test('should return null from api getter by default', () async {
      expect(module.api, isNull);
    });

    test('should return null from components getter by default', () async {
      expect(module.components, isNull);
    });

    test('should return null from events getter by default', () async {
      expect(module.events, isNull);
    });
  });
}
