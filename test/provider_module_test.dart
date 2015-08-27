@TestOn('vm || browser')
library w_module.test.provider_module_test;

import 'dart:async';

import 'package:w_module/w_module.dart';
import 'package:test/test.dart';

class TestProviderModule extends ProviderModule {
  get data => 'dummy_data';
}

void main() {
  group('ProviderModule', () {
    TestProviderModule module;

    setUp(() {
      module = new TestProviderModule();
    });

    test('should have a listen method that is passed through to its stream',
        () async {
      Completer completer = new Completer();

      module.listen((TestProviderModule payload) {
        expect(payload is TestProviderModule, isTrue);
        expect(payload.data, equals('dummy_data'));
        completer.complete();
      });

      module.trigger();
      return completer.future;
    });

    test('should add to stream on trigger', () async {
      Completer completer = new Completer();

      module.stream.listen((TestProviderModule payload) {
        expect(payload is TestProviderModule, isTrue);
        expect(payload.data, equals('dummy_data'));
        completer.complete();
      });

      module.trigger();
      return completer.future;
    });

    test('should have a doApiCall method that performs optomostic triggers',
        () async {
      Completer completer = new Completer();

      // TODO how to test this?
      completer.complete();

      return completer.future;
    });
  });
}
