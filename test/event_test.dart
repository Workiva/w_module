@TestOn('vm || browser')
library w_module.test.event_test;

import 'dart:async';

import 'package:w_module/w_module.dart';
import 'package:test/test.dart';

void main() {
  group('Event', () {
    Event<String> event;
    DispatchKey key;

    setUp(() {
      key = new DispatchKey('test');
      event = new Event<String>(key);
    });

    test('should inherit from Stream', () {
      expect(event is Stream, isTrue);
    });

    test('should provide means to listen to the stream it was created from',
        () async {
      Completer completer = new Completer();

      event.listen((payload) {
        expect(payload, equals('trigger'));
        completer.complete();
      });

      event('trigger', key);
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

      event('water', key);
      return completer.future;
    });

    test('should only allow dispatch with correct key', () async {
      Completer completer = new Completer();

      event.listen((payload) {
        if (payload == 'bad') throw new Exception(
            'Should not be able to dispatch events without the correct key.');
        if (payload == 'good') {
          completer.complete();
        }
      });

      // Create a new dispatch key that should not work for this event.
      DispatchKey incorrectKey = new DispatchKey('incorrect');

      expect(() {
        event('bad', incorrectKey);
      }, throwsArgumentError);
      event('good', key);

      await completer.future;
    });
  });
}
