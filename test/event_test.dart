library w_module.test.event_test;

import 'dart:async';

import 'package:w_module/w_module.dart';
import 'package:test/test.dart';

void main() {
  group('Event', () {
    Event<String> event;

    setUp(() {
      event = new Event<String>();
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

      event('trigger');
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

      event('water');
      return completer.future;
    });

    test('should be able to obtain a read-only view', () async {
      Event<String> readOnlyEvent = event.readOnly;
      expect(() {
        readOnlyEvent('not allowed!');
      }, throwsStateError);

      Completer c = new Completer();
      readOnlyEvent.listen((payload) {
        expect(payload, equals('allowed'));
        c.complete();
      });

      event('allowed');
      await c.future;
    });
  });
}
