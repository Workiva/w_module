library w_module.src.event;

import 'dart:async';

class Event<T> extends Stream<T> {
  /// This event is associated with a specific dispatch key.
  /// In order to control this event stream, this dispatch
  /// key must be used. Without it, this event stream is
  /// effectively read-only.
  DispatchKey _key;

  /// Sink where new items to this event stream are added.
  Sink<T> _sink;

  /// Underlying stream that listeners subscribe to.
  Stream<T> _stream;

  /// Create an Event and associate it with [key].
  Event(DispatchKey key) : _key = key {
    var c = new StreamController.broadcast();
    _sink = c.sink;
    _stream = c.stream;
  }

  StreamSubscription<T> listen(void onData(T event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  /// Dispatch a payload to this event stream. This only works if
  /// [key] is the correct key with which this Event was constructed.
  void call(T payload, DispatchKey key) {
    if (key != _key) throw new ArgumentError(
        'Event dispatch expected the "${_key.name}" key but received the "${key.name}" key.');
    _sink.add(payload);
  }
}

/// Key that enables dispatching of events. Every [Event] is
/// associated with a specific key, and that key must be used
/// in order to dispatch an item to that event stream.
///
/// One key can be used for multiple events.
class DispatchKey {
  String name;
  DispatchKey([String this.name]);
}
