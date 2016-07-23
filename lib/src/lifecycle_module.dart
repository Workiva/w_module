// Copyright 2015 Workiva Inc.
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

library w_module.src.lifecycle_module;

import 'dart:async';

/// Intended to be extended by most base module classes in order to provide a
/// unified lifecycle API.
abstract class LifecycleModule {
  /// Name of the module for identification within exceptions and while debugging.
  String get name => 'Module';

  /// List of child components so that lifecycle can iterate over them as needed
  List<LifecycleModule> _childModules = [];
  Iterable<LifecycleModule> get childModules => _childModules;

  // Broadcast streams for the module's lifecycle events.

  /// Event dispatched at beginning of module.load() logic
  StreamController<LifecycleModule> _willLoadController;
  Stream<LifecycleModule> get willLoad => _willLoadController.stream;

  /// Event dispatched at end of module.load() logic
  StreamController<LifecycleModule> _didLoadController;
  Stream<LifecycleModule> get didLoad => _didLoadController.stream;

  /// Event dispatched at beginning of module.unload() logic
  StreamController<LifecycleModule> _willUnloadController;
  Stream<LifecycleModule> get willUnload => _willUnloadController.stream;

  /// Event dispatched at end of module.unload() logic
  StreamController<LifecycleModule> _didUnloadController;
  Stream<LifecycleModule> get didUnload => _didUnloadController.stream;

  /// Event dispatched at the beginning of module.loadChildModule() logic
  StreamController<LifecycleModule> _willLoadChildModuleController;
  Stream<LifecycleModule> get willLoadChildModule =>
      _willLoadChildModuleController.stream;

  /// Event dispatched at end of module.loadChildModule() logic
  StreamController<LifecycleModule> _didLoadChildModuleController;
  Stream<LifecycleModule> get didLoadChildModule =>
      _didLoadChildModuleController.stream;

  /// Event dispatched before a child module is unloaded
  StreamController<LifecycleModule> _willUnloadChildModuleController;
  Stream<LifecycleModule> get willUnloadChildModule =>
      _willUnloadChildModuleController.stream;

  /// Event dispatched after a child module is unloaded
  StreamController<LifecycleModule> _didUnloadChildModuleController;
  Stream<LifecycleModule> get didUnloadChildModule =>
      _didUnloadChildModuleController.stream;

  final Map<LifecycleModule, StreamSubscription<LifecycleModule>>
      _willUnloadChildModuleSubscriptions = {};
  final Map<LifecycleModule, StreamSubscription<LifecycleModule>>
      _didUnloadChildModuleSubscriptions = {};

  // constructor necessary to init load / unload state stream
  LifecycleModule() {
    _willLoadController = new StreamController<LifecycleModule>.broadcast();
    _didLoadController = new StreamController<LifecycleModule>.broadcast();
    _willUnloadController = new StreamController<LifecycleModule>.broadcast();
    _didUnloadController = new StreamController<LifecycleModule>.broadcast();
    _willLoadChildModuleController =
        new StreamController<LifecycleModule>.broadcast();
    _didLoadChildModuleController =
        new StreamController<LifecycleModule>.broadcast();
    _willUnloadChildModuleController =
        new StreamController<LifecycleModule>.broadcast();
    _didUnloadChildModuleController =
        new StreamController<LifecycleModule>.broadcast();
  }

  //--------------------------------------------------------
  // Public methods that can be used directly to trigger
  // module lifecycle / check current lifecycle state
  //--------------------------------------------------------

  /// Public method to trigger the loading of a Module.
  /// Calls the onLoad() method, which can be implemented on a Module.
  /// Executes the willLoad and didLoad event streams.
  Future load() {
    Completer completer = new Completer();
    _willLoadController.add(this);
    onLoad().then((_) {
      _didLoadController.add(this);
      completer.complete();
    });
    return completer.future;
  }

  /// Public method to async load a child module and register it
  /// for lifecycle management.
  Future loadChildModule(LifecycleModule newModule) {
    if (_childModules.contains(newModule)) {
      return new Future(() {});
    }
    Completer completer = new Completer();
    onWillLoadChildModule(newModule);
    _willLoadChildModuleController.add(newModule);
    _willUnloadChildModuleSubscriptions[newModule] =
        newModule.willUnload.listen((_) {
      onWillUnloadChildModule(newModule);
      _willUnloadChildModuleController.add(newModule);
      _childModules.remove(newModule);
      _willUnloadChildModuleSubscriptions[newModule].cancel();
      _willUnloadChildModuleSubscriptions.remove(newModule);
    });
    _didUnloadChildModuleSubscriptions[newModule] =
        newModule.didUnload.listen((_) {
      onDidUnloadChildModule(newModule);
      _didUnloadChildModuleController.add(newModule);
      _didUnloadChildModuleSubscriptions[newModule].cancel();
      _didUnloadChildModuleSubscriptions.remove(newModule);
    });
    newModule.load().then((_) {
      _childModules.add(newModule);
      onDidLoadChildModule(newModule);
      _didLoadChildModuleController.add(newModule);
      completer.complete();
    });
    return completer.future;
  }

  /// Public method to query the unloadable state of the Module.
  /// Calls the onShouldUnload() method, which can be implemented on a Module.
  /// onShouldUnload is also called on all registered child modules.
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
  Future unload() {
    Completer completer = new Completer();
    ShouldUnloadResult canUnload = shouldUnload();
    if (canUnload.shouldUnload) {
      _willUnloadController.add(this);
      Iterable<Future> unloadChildren = _childModules.map((c) => c.unload());
      Future.wait(unloadChildren).then((_) {
        _childModules.clear();
        onUnload().then((_) {
          _didUnloadController.add(this);
          completer.complete();
        });
      });
    } else {
      // reject with shouldUnload messages
      throw new ModuleUnloadCanceledException(canUnload.messagesAsString());
    }
    return completer.future;
  }

  //--------------------------------------------------------
  // Methods that can be optionally implemented by subclasses
  // to execute code during certain phases of the module
  // lifecycle
  //--------------------------------------------------------

  /// Custom logic to be executed when a child module is to be loaded.
  Future onWillLoadChildModule(LifecycleModule module) async {}

  /// Custom logic to be executed when a child module has been loaded.
  Future onDidLoadChildModule(LifecycleModule module) async {}

  /// Custom logic to be executed when a child module is to be unloaded.
  Future onWillUnloadChildModule(LifecycleModule module) async {}

  /// Custom logic to be executed when a child module has been unloaded.
  Future onDidUnloadChildModule(LifecycleModule module) async {}

  /// Custom logic to be executed during load.
  /// Initial data queries and interactions with the server can be triggered
  /// here.  Returns a future with no payload that completes when the module has
  /// finished loading.
  Future onLoad() async {}

  /// Custom logic to be executed during shouldUnload (consequently also in unload).
  /// Returns a ShouldUnloadResult.
  /// [ShouldUnloadResult.shouldUnload == true] indicates that the module is safe to unload.
  /// [ShouldUnloadResult.shouldUnload == false] indicates that the module should not be unloaded.
  /// In this case, ShouldUnloadResult.messages contains a list of string messages indicating
  /// why unload was rejected.
  ShouldUnloadResult onShouldUnload() {
    return new ShouldUnloadResult();
  }

  /// Custom logic to be executed during unload.
  /// Called on unload if shouldUnload completes with true. This can be used for
  /// cleanup. Returns a future with no payload that completes when the module
  /// has finished unloading.
  Future onUnload() async {}
}

/// Exception thrown when unload fails.
class ModuleUnloadCanceledException implements Exception {
  String message;

  ModuleUnloadCanceledException(this.message);
}

/// A set of messages returned from the hierarchical application of shouldUnload
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
