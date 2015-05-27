library w_module.src.event;

import 'dart:async';

class Event<T> extends Stream<T> {

  Stream<T> _stream;

  Event.fromStream(this._stream);

  StreamSubscription<T> listen(void onData(T event), {Function onError, void onDone(), bool cancelOnError}) {
    return _stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

}
