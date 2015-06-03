library w_module.test.lifecycle_module_test;

import 'dart:async';

import 'package:w_module/w_module.dart';
import 'package:test/test.dart';

class TestLifecycleModule extends LifecycleModule {}

void main() {
  group('LifecycleModule', () {
    TestLifecycleModule module;

    setUp(() {
      module = new TestLifecycleModule();
    });

    test('should call onLoad when module is loaded', () async {
      Completer completer = new Completer();

      // TODO how to test?
      completer.complete();

      return completer.future;
    });

    test('should call onUnload when module is unloaded', () async {
      Completer completer = new Completer();

      // TODO how to test?
      completer.complete();

      return completer.future;
    });

    test('should not unload module if shouldUnload completes false', () async {
      Completer completer = new Completer();

      // TODO how to test?
      completer.complete();

      return completer.future;
    });
  });
}
