library w_module.test.event_test;

import 'dart:async';

import 'package:w_module/w_module.dart';
import 'package:test/test.dart';

void main() {
  group('Event', () {
    Event<String> event;
    StreamController streamController;

    setUp(() {
      streamController = new StreamController<String>();
      event = new Event<String>.fromStream(streamController.stream);
    });

    test('should inherit from Stream', () {
      expect(event is Stream, isTrue);
    });

    test('should provide means to listen to the stream it was created from', () async {
      Completer completer = new Completer();

      event.listen((payload) {
        expect(payload, equals('trigger'));
        completer.complete();
      });

      streamController.add('trigger');
      return completer.future;
    });

    test('should support other stream methods', () async {
      Completer completer = new Completer();

      // The point of this test is to exercise the `where` method which is made available
      // on an action by extending stream and overriding `listen`
      Stream<String> filteredStream = event.where((value) => value == 'water');
      expectAsync(filteredStream.listen)((payload) {
        expect(payload, equals('water'));
        completer.complete();
      });

      streamController.add('water');
      return completer.future;
    });
  });
}
