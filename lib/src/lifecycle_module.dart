library w_module.src.lifecycle_module;

import 'dart:async';

/// Intended to be extended by most base module classes in order to provide a unified
/// lifecycle API.
abstract class LifecycleModule {

  /// Name of the module for identification within exceptions and while debugging.
  String name = 'Module';

  // current loaded state
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// List of child components so that lifecycle can iterate over them as needed
  List<LifecycleModule> _childModules = [];

  //--------------------------------------------------------
  // Public methods that can be used directly to trigger
  // module lifecycle / check current lifecycle state
  //--------------------------------------------------------

  /// Public method to trigger the loading of a Module.
  /// Calls the onLoad() method, which can be implemented on a Module.
  /// Executes the willLoad() and didLoad() callbacks, which can be implemented on a Module.
  Future load() async {
    willLoad();
    await onLoad();
    _isLoaded = true;
    didLoad();
  }

  /// Public method to async load a child module and register it
  /// for lifecycle management
  Future loadModule(LifecycleModule newModule) async {
    _childModules.add(newModule);
    // TODO - register a handler for newModule.willUnload to remove it from this module's children list
    await newModule.load();
  }

  // TODO - do we need an explicit unloadModule too? - YES

  /// Public method to query the unloadable state of the Module.
  /// Calls the onShouldUnload() method, which can be implemented on a Module.
  /// onShouldUnload is also called on all registered child modules
  ShouldUnloadResult shouldUnload() {

    // collect results from all child modules and self
    List<ShouldUnloadResult> shouldUnloads = [];
    _childModules.forEach((child) {
      shouldUnloads.add(child.shouldUnload());
    });
    shouldUnloads.add(onShouldUnload());

    // aggregate into 1 combined result
    ShouldUnloadResult finalResult = new ShouldUnloadResult();
    shouldUnloads.forEach((res) {
      if (!res.shouldUnload) {
        finalResult.shouldUnload = false;
        finalResult.messages.addAll(res.messages);
      }
    });
    return finalResult;
  }

  /// Public method to trigger the Module unload cycle.
  /// Calls shouldUnload(), and, if that completes successfully,
  /// continues to call onUnload() on the module and all registered child modules.
  /// If unloading is rejected, this method will complete with an error.
  Future unload() async {
    ShouldUnloadResult canUnload = shouldUnload();
    if (canUnload.shouldUnload) {
      willUnload();
      List<Future> unloadChildren = [];
      for (num i = 0; i < _childModules.length; i++) {
        unloadChildren.add(_childModules[i].unload());
      }
      await Future.wait(unloadChildren);
      _childModules.clear();
      await onUnload();
      _isLoaded = false;
      didUnload();
    } else {
      //  reject with shouldUnload messages
      throw new ModuleUnloadCanceledException(canUnload.messagesAsString());
    }
  }

  //--------------------------------------------------------
  // Methods that can be optionally implemented by subclasses
  // to execute code during certain phases of the module
  // lifecycle
  //--------------------------------------------------------

  /// Initial data queries & interactions with the server should be triggered here.
  /// Completes a future with no payload indicating that the module has finished loading.
  Future onLoad() async {}

  /// Returns a bool.
  /// [false] indicates that the module should not be unloaded
  /// [true] indicates that the module is safe to unload
  ShouldUnloadResult onShouldUnload() {
    return new ShouldUnloadResult();
  }

  /// Called on unload if shouldUnload completes with true.
  /// Use this for cleanup.
  /// Completes a future with no payload indicating that the module has finished unloading.
  Future onUnload() async {}

  // Callbacks that can be overridden to be notified of lifecycle changes
  // TODO - make these streams so multiple people can listen for the events?
  Function willLoad = () {};
  Function didLoad = () {};
  Function willUnload = () {};
  Function didUnload = () {};
}

class ModuleUnloadCanceledException implements Exception {
  String message;

  ModuleUnloadCanceledException(this.message);
}

class ShouldUnloadResult {
  bool shouldUnload;
  List<String> messages;

  ShouldUnloadResult([this.shouldUnload = true, String message]) {
    messages = [];
    if (message != null) {
      messages.add(message);
    }
  }

  bool call() => shouldUnload;

  String messagesAsString() {
    return messages.join('\n');
  }
}
