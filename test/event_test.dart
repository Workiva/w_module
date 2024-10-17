// Copyright 2017 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@TestOn('browser')
import 'dart:async';

import 'package:test/test.dart';
import 'package:w_module/w_module.dart';

void main() {
  group('Event', () {
    late Event<String> event;
    late DispatchKey key;

    setUp(() {
      key = DispatchKey('test');
      event = Event<String>(key);
    });

    test('should provide means to listen to the stream it was created from',
        () async {
      Completer completer = Completer();

      event.listen((payload) {
        expect(payload, equals('trigger'));
        completer.complete();
      });

      event('trigger', key);
      return completer.future;
    });

    test('should support other stream methods', () async {
      Completer completer = Completer();

      // The point of this test is to exercise the `where` method which is made available
      // on an action by extending stream and overriding `listen`
      Stream<String> filteredStream = event.where((value) => value == 'water');
      filteredStream.listen(expectAsync1((payload) {
        expect(payload, equals('water'));
        completer.complete();
      }));

      event('water', key);
      return completer.future;
    });

    test('should only allow dispatch with correct key', () async {
      Completer completer = Completer();

      event.listen((payload) {
        if (payload == 'bad')
          throw Exception(
              'Should not be able to dispatch events without the correct key.');
        if (payload == 'good') {
          completer.complete();
        }
      });

      // Create a new dispatch key that should not work for this event.
      DispatchKey incorrectKey = DispatchKey('incorrect');

      expect(() {
        event('bad', incorrectKey);
      }, throwsArgumentError);
      event('good', key);

      await completer.future;
    });

    test('should be closable', () async {
      expect(event.isClosed, isFalse);
      await event.close(key);
      expect(event.isClosed, isTrue);
    });

    test('should only allow closing with correct key', () async {
      // Create a new dispatch key that should not work for this event.
      DispatchKey incorrectKey = DispatchKey('incorrect');

      expect(event.close(incorrectKey), throwsArgumentError);
    });

    test('should not allow events to be dispatched after being closed',
        () async {
      await event.close(key);
      expect(() {
        event('too late', key);
      }, throwsStateError);
    });
  });
}
