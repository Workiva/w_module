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

  /// This method provides a shortcut for performing optimistic updates
  /// on the public `data`. It is intended to wrap an async api function
  /// that would first update `data` synchronously and then perform an
  /// async request to persist the change(s).
  Future doApiCall(Future future) {
    // This first trigger performs the optimistic update so that any `data`
    // that was updated 'optimistically' (prior to persistence) in the api
    // call will be picked up by this module's subscribers ASAP.
    trigger();
    return future.then((value) {
      // This trigger will happen after the asynchronous portion of the api
      // call is complete (e.g. the data is persisted successfully). Perhaps
      // additional `data` is modified as the result of the async action;
      // this trigger handles those kind of changes.
      trigger();
    }).catchError((error) {
      // This trigger will occur in the event that the api request fails.
      // `data` would likely be updated to reflect an error state of some
      // kind. This trigger handles those situations.
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
    return _stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}
