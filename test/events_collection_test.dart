// @dart=2.7
// ^ Do not remove until migrated to null safety. More info at https://wiki.atl.workiva.net/pages/viewpage.action?pageId=189370832
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

@TestOn('vm || browser')
import 'package:test/test.dart';
import 'package:w_module/w_module.dart';

final _key = DispatchKey('test');

class TestEvents extends EventsCollection {
  @override
  String get disposableTypeName => 'TestEvents';

  final Event<String> eventA = Event<String>(_key);
  final Event<String> eventB = Event<String>(_key);

  TestEvents() : super(_key) {
    [
      eventA,
      eventB,
    ].forEach(manageEvent);
  }
}

void main() {
  group('EventsCollection', () {
    test('manageEvent() should close Events when the collection is disposed',
        () async {
      final eventsCollection = TestEvents();
      expect(eventsCollection.eventA.isClosed, isFalse);
      expect(eventsCollection.eventB.isClosed, isFalse);
      await eventsCollection.dispose();
      expect(eventsCollection.eventA.isClosed, isTrue);
      expect(eventsCollection.eventB.isClosed, isTrue);
    });
  });
}
