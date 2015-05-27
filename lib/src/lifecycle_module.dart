library w_module.src.lifecycle_module;

import 'dart:async';

/// Intended to be extended by most base module classes in order to provide a unified
/// lifecycle API.
abstract class LifecycleModule {

  /// Name of the module for identification within exceptions and while debugging.
  String name = 'Module';

  /// Public method to trigger the loading of a Module.
  /// Calls the onLoad() method, which can be implemented on a Module.
  Future load() {
    return onLoad();
  }

  /// To be optionally implemented by subclasses.
  /// Initial data queries & interactions with the server should be triggered here.
  /// Completes a future with no payload indicating that the module has finished loading.
  Future onLoad() {
    return new Future.value();
  }

  /// Public method to trigger the Module unload cycle.
  /// Calls shouldUnload(), and if that completes with true it continues to call onUnload().
  /// If unloading is canceled, this method will complete with an error.
  Future unload() async {
    bool should;

    try {
      should = await shouldUnload();
    } catch (error) {
      return onUnload();
    }

    if (should) {
      return onUnload();
    } else {
      throw new ModuleUnloadCanceledException(
          '${name} canceled the unload cycle.');
    }
  }

  /// To be optionally implemented by subclasses.
  /// Returns a future. Complete the future with [false] to prevent the module from unloading.
  /// Complete with [true] to continue the lifecycle.
  Future<bool> shouldUnload() {
    return new Future.value(true);
  }

  /// To be optionally implemented by subclasses.
  /// Called on unload if shouldUnload completes with true.
  /// Use this for cleanup.
  /// Completes a future with no payload indicating that the module has finished unloading.
  Future onUnload() {
    return new Future.value();
  }
}

class ModuleUnloadCanceledException implements Exception {
  String message;

  ModuleUnloadCanceledException(this.message);
}
