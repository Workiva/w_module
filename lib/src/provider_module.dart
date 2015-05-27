library w_module.src.provider_module;

import 'dart:async';

import 'lifecycle_module.dart';

abstract class ProviderModule extends LifecycleModule {
  Object get data;

  StreamController<ProviderModule> _streamController;
  Stream<ProviderModule> _stream;
  Stream<ProviderModule> get stream => _stream;

  ProviderModule() {
    _streamController = new StreamController<ProviderModule>();
    _stream = _streamController.stream.asBroadcastStream();
  }

  Future doApiCall(Future future) {
    trigger();
    return future.then((value) {
      trigger();
    }).catchError((error) {
      trigger();
    });
  }

  void trigger() {
    _streamController.add(this);
  }

  // Pass-through listen function to save some typing
  // (provider.listen(...) instead of provider.stream.listen(...))
  StreamSubscription<ProviderModule> listen(void onData(ProviderModule event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}
