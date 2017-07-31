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

import 'package:meta/meta.dart';
import 'package:w_common/disposable.dart';

import 'package:w_module/src/event.dart';

/// A base class for a collection of [Event] instances that are all tied to the
/// same [DispatchKey].
///
/// Use this class to colocate related [Event] instances and to make disposal of
/// these [Event]s easier.
///
///     final key = new DispatchKey('example');
///
///     class ExampleEvents extends EventsCollection {
///       final Event<String> eventA = new Event<String>(key);
///       final Event<String> eventB = new Event<String>(key);
///
///       ExampleEvents() : super(key) {
///         [
///           eventA,
///           eventB,
///         ].forEach(manageEvent);
///       }
///     }
class EventsCollection extends Disposable {
  /// The key that every [Event] instance included as a part of this
  /// [EventsCollection] should be tied to.
  ///
  /// This allows [manageEvent] to close the aforementioned [Event]s.
  final DispatchKey _key;

  EventsCollection(DispatchKey key) : _key = key;

  /// Registers an [Event] to be closed when this [EventsCollection] is
  /// disposed.
  @mustCallSuper
  @protected
  void manageEvent(Event event) {
    getManagedDisposer(() => event.close(_key));
  }
}
