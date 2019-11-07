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

library w_module.src.event;

import 'dart:async';

/// An event stream that can be listened to.  A dispatch key is required to
/// instantiate the event stream.  The same dispatch key must subsequently be
/// used to dispatch all events on the stream, effectively preventing
/// uncontrolled external dispatch.
class Event<T> extends Stream<T> {
  /// This event is associated with a specific dispatch key.
  /// In order to control this event stream, this dispatch
  /// key must be used. Without it, this event stream is
  /// effectively read-only.
  DispatchKey _key;

  /// The underlying StreamController that drives the dispatching of and
  /// listening for events.
  final StreamController<T> _streamController = StreamController<T>.broadcast();

  /// Create an Event and associate it with [key].
  Event(DispatchKey key) : _key = key;

  /// Whether the Event stream is closed.
  ///
  /// The Event becomes closed by calling the [close] method. New events cannot
  /// be dispatched when this is `true`.
  bool get isClosed => _streamController.isClosed;

  /// Closes the Event stream, telling it that no further events will be
  /// dispatched.
  ///
  /// Returns a `Future` which resolves when the underlying `StreamController`
  /// has finished closing.
  Future<Null> close(DispatchKey key) async {
    if (key != _key) {
      throw ArgumentError(
          'Event.close() expected the "${_key.name}" key but received the '
          '"${key.name}" key.');
    }
    await _streamController.close();
  }

  @override
  StreamSubscription<T> listen(void onData(T event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _streamController.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  /// Dispatch a payload to this event stream. This only works if
  /// [key] is the correct key with which this Event was constructed.
  void call(T payload, DispatchKey key) {
    if (key != _key) {
      throw ArgumentError(
          'Event dispatch expected the "${_key.name}" key but received the '
          '"${key.name}" key.');
    }
    _streamController.add(payload);
  }
}

/// Key that enables dispatching of events. Every [Event] is
/// associated with a specific key, and that key must be used
/// in order to dispatch an item to that event stream.
///
/// One key can be used for multiple events.
class DispatchKey {
  String name;
  DispatchKey([this.name]);
}
