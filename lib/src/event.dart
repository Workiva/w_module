library w_module.src.event;

import 'dart:async';

class Event<T> extends Stream<T> implements Function {
  /// When an [Event] is in "read-only" mode, the call()
  /// method will throw a [StateError]. It is safe to expose
  /// read-only events to external consumers.
  final bool _isReadOnly;

  Sink<T> _sink;
  Stream<T> _stream;

  /// Create a new event that can be controlled and listened to.
  Event() : _isReadOnly = false {
    var controller = new StreamController();
    _sink = controller.sink;
    _stream = controller.stream;
  }

  /// Create a read-only version of an existing Event.
  Event._readOnly(Event<T> event) : _isReadOnly = true {
    _stream = event._stream;
  }

  Event<T> get readOnly => new Event._readOnly(this);

  /// Dispatch an event instance.
  void call(T event) {
    if (_isReadOnly) throw new StateError('Event is in read-only mode.');
    _sink.add(event);
  }

  /// Listen to this event stream.
  StreamSubscription<T> listen(void onData(T event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

abstract class EventCollection<T> {
  T get readOnly;
}


/////////////////////////////////////////////////////////////
/// Required Code
/////////////////////////////////////////////////////////////
//
//@GenerateReadOnly()
//class ExampleEvents extends EventCollection<ExampleEvents> {
//  Event<String> _onSomething = new Event<String>();
//  Event<int> _onSomethingElse = new Event<int>();
//
//  ExampleEvents get readOnly => new ReadOnlyExampleEvents(this);
//}
//
/////////////////////////////////////////////////////////////
/// Potentially Generated Code
/////////////////////////////////////////////////////////////
//
//class ReadOnlyExampleEvents implements ExampleEvents {
//  Event<String> onSomething;
//  Event<int> onSomethingElse;
//
//  ReadOnlyExampleEvents(ExampleEvents original) {
//    onSomething = original.onSomething.readOnly;
//    onSomethingElse = original.onSomethingElse.readOnly;
//  }
//}