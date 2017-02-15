@TestOn('vm || browser')
import 'package:w_module/w_module.dart';
import 'package:test/test.dart';

class TestModule extends SimpleModule {}

void main() {
  group('SimpleModuleModule', () {
    TestModule simpleModule;

    setUp(() {
      simpleModule = new TestModule();
    });

    test('should return null from api getter by default', () {
      expect(simpleModule.api, isNull);
    });

    test('should return null from components getter by default', () {
      expect(simpleModule.components, isNull);
    });

    test('should return null from events getter by default', () {
      expect(simpleModule.events, isNull);
    });
  });
}
