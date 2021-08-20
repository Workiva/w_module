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

library w_module.src.request;

import 'package:w_module/src/dispatch_key.dart';

/// Like an event except the subscriber must return something
class Request<T, S> {
  /// This event is associated with a specific dispatch key.
  /// In order to control this event stream, this dispatch
  /// key must be used. Without it, this event stream is
  /// effectively read-only.
  DispatchKey _key;

  S Function(T event) _onData;

  /// Create an Event and associate it with [key].
  Request(DispatchKey key) : _key = key;

  bool get hasListener => _onData != null;

  void listen(S onData(T event)) {
    _onData = onData;
  }

  /// Dispatch a payload to this event stream. This only works if
  /// [key] is the correct key with which this Event was constructed.
  S call(T payload, DispatchKey key) {
    if (key != _key) {
      throw ArgumentError(
          'Event dispatch expected the "${_key.name}" key but received the '
          '"${key.name}" key.');
    }
    if (_onData == null) {
      throw StateError('the request has not been listened to');
    }
    return _onData(payload);
  }
}
