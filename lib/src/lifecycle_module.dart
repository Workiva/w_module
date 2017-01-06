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

import 'package:logging/logging.dart';
import 'package:meta/meta.dart' show protected, required;
import 'package:w_common/disposable.dart';

/// Possible states a [LifecycleModule] may occupy.
enum LifecycleState {
  /// The module has been instantiated.
  instantiated,

  /// The module is in the process of being loaded.
  loading,

  /// The module has been loaded.
  loaded,

  /// The module is in the process of being suspended.
  suspending,

  /// The module has been suspended.
  suspended,

  /// The module is in the process of resuming from the suspended state.
  resuming,

  /// The module is in the process of unloading.
  unloading,

  /// The module has been unloaded.
  unloaded
}

/// Intended to be extended by most base module classes in order to provide a
/// unified lifecycle API.
abstract class LifecycleModule implements DisposableManager {
  final Disposable _disposableProxy = new Disposable();
  Logger _logger;
  String _name = 'Module';
  LifecycleState _state = LifecycleState.instantiated;
  Future<Null> _transitionFuture;

  // constructor necessary to init load / unload state stream
  LifecycleModule() {
    // The didUnload event must be emitted after disposal which requires that
    // the stream controller must be disposed of manually at the end of the
    // unload transition.
    _didUnloadController = new StreamController<LifecycleModule>.broadcast();

    [
      _willLoadController = new StreamController<LifecycleModule>.broadcast(),
      _didLoadController = new StreamController<LifecycleModule>.broadcast(),
      _willUnloadController = new StreamController<LifecycleModule>.broadcast(),
      _willLoadChildModuleController =
          new StreamController<LifecycleModule>.broadcast(),
      _didLoadChildModuleController =
          new StreamController<LifecycleModule>.broadcast(),
      _willUnloadChildModuleController =
          new StreamController<LifecycleModule>.broadcast(),
      _didUnloadChildModuleController =
          new StreamController<LifecycleModule>.broadcast(),
      _willSuspendController =
          new StreamController<LifecycleModule>.broadcast(),
      _didSuspendController = new StreamController<LifecycleModule>.broadcast(),
      _willResumeController = new StreamController<LifecycleModule>.broadcast(),
      _didResumeController = new StreamController<LifecycleModule>.broadcast()
    ].forEach(manageStreamController);

    _logger = new Logger('w_module');
  }

  /// Name of the module for identification in exceptions and debug messages.
  // ignore: unnecessary_getters_setters
  String get name => _name;

  /// Deprecated: the module name should be defined by overriding the getter in
  /// a subclass and it should not be mutable.
  @deprecated
  // ignore: unnecessary_getters_setters
  set name(String newName) {
    _name = newName;
  }

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

  /// Event dispatched at the beginning of the module.suspend() logic
  StreamController<LifecycleModule> _willSuspendController;
  Stream<LifecycleModule> get willSuspend => _willSuspendController.stream;

  /// Event dispatched at the end of the module.suspend() logic
  StreamController<LifecycleModule> _didSuspendController;
  Stream<LifecycleModule> get didSuspend => _didSuspendController.stream;

  /// Event dispatched at the beginning of the module.resume() logic
  StreamController<LifecycleModule> _willResumeController;
  Stream<LifecycleModule> get willResume => _willResumeController.stream;

  /// Event dispatched at the end of the module.resume() logic
  StreamController<LifecycleModule> _didResumeController;
  Stream<LifecycleModule> get didResume => _didResumeController.stream;

  /// Event dispatched at beginning of module.unload() logic
  StreamController<LifecycleModule> _willUnloadController;
  Stream<LifecycleModule> get willUnload => _willUnloadController.stream;

  /// Event dispatched at end of module.unload() logic
  StreamController<LifecycleModule> _didUnloadController;
  Stream<LifecycleModule> get didUnload => _didUnloadController.stream;

  final Map<LifecycleModule, StreamSubscription<LifecycleModule>>
      _willUnloadChildModuleSubscriptions = {};
  final Map<LifecycleModule, StreamSubscription<LifecycleModule>>
      _didUnloadChildModuleSubscriptions = {};

  /// Whether the module is currently instantiated.
  bool get isInstantiated => _state == LifecycleState.instantiated;

  /// Whether the module is currently loaded.
  bool get isLoaded => _state == LifecycleState.loaded;

  /// Whether the module is currently loading.
  bool get isLoading => _state == LifecycleState.loading;

  /// Whether the module is currently resuming.
  bool get isResuming => _state == LifecycleState.resuming;

  /// Whether the module is currently suspended.
  bool get isSuspended => _state == LifecycleState.suspended;

  /// Whether the module is currently suspending.
  bool get isSuspending => _state == LifecycleState.suspending;

  /// Whether the module is currently unloaded.
  bool get isUnloaded => _state == LifecycleState.unloaded;

  /// Whether the module is currently unloading.
  bool get isUnloading => _state == LifecycleState.unloading;

  //--------------------------------------------------------
  // Public methods that can be used directly to trigger
  // module lifecycle / check current lifecycle state
  //--------------------------------------------------------

  /// Public method to trigger the loading of a Module.
  ///
  /// Calls the onLoad() method, which can be implemented on a Module.
  /// Executes the willLoad and didLoad event streams.
  ///
  /// Initiates the loading process when the module is in the instantiated
  /// state. If the module is in the loaded or loading state a warning is logged
  /// and the method is a noop. If the module is in any other state, a
  /// StateError is thrown.
  ///
  /// Note that [LifecycleModule] only supports one load/unload cycle. If [load]
  /// is called after a module has been unloaded, a [StateError] is thrown.
  Future<Null> load() {
    if (isLoading || isLoaded) {
      return _buildNoopResponse(
          isTransitioning: isLoading,
          methodName: 'load',
          currentState:
              isLoading ? LifecycleState.loading : LifecycleState.loaded);
    }

    if (!isInstantiated) {
      return _buildIllegalTransitionResponse(
          reason: 'A module can only be loaded once.');
    }

    _state = LifecycleState.loading;
    final completer = new Completer<Null>();
    _transitionFuture = completer.future;
    _willLoadController.add(this);

    onLoad().then((_) {
      _state = LifecycleState.loaded;
      _didLoadController.add(this);
      _transitionFuture = null;
      completer.complete();
    });

    return completer.future;
  }

  /// Public method to async load a child module and register it
  /// for lifecycle management.
  @protected
  Future<Null> loadChildModule(LifecycleModule newModule) {
    if (_childModules.contains(newModule)) {
      return new Future(() {});
    }
    final completer = new Completer<Null>();
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

  /// Ensures a given [Disposable] is disposed when the [LifecycleModule] is
  /// unloaded.
  @override
  void manageDisposable(Disposable disposable) =>
      _disposableProxy.manageDisposable(disposable);

  /// Ensures a given [Disposer] callback is called when the module is unloaded.
  @override
  void manageDisposer(Disposer disposer) =>
      _disposableProxy.manageDisposer(disposer);

  /// Ensures a given [StreamController] is closed when the module is unloaded.
  @override
  void manageStreamController(StreamController controller) =>
      _disposableProxy.manageStreamController(controller);

  /// Ensures a given [StreamSubscription] is cancelled when the module is
  /// unloaded.
  @override
  void manageStreamSubscription(StreamSubscription subscription) =>
      _disposableProxy.manageStreamSubscription(subscription);

  /// Public method to suspend the module.
  ///
  /// Suspend indicates to the module that it should go into a low-activity
  /// state. For example, by disconnecting from backend services and unloading
  /// heavy data structures.
  ///
  /// Initiates the suspend process when the module is in the loaded state. If
  /// the module is in the suspended or suspending state a warning is logged and
  /// the method is a noop. If the module is in any other state, a StateError is
  /// thrown.
  Future<Null> suspend() {
    if (isSuspended || isSuspending) {
      return _buildNoopResponse(
          isTransitioning: isSuspending,
          methodName: 'suspend',
          currentState: isSuspending
              ? LifecycleState.suspending
              : LifecycleState.suspended);
    }

    if (!isLoaded) {
      return _buildIllegalTransitionResponse(
          targetState: LifecycleState.suspended,
          allowedStates: [LifecycleState.loaded]);
    }

    _state = LifecycleState.suspending;
    final completer = new Completer<Null>();
    _transitionFuture = completer.future;
    _willSuspendController.add(this);

    Future.wait(_childModules.map((c) => c.suspend())).then((_) {
      onSuspend().then((_) {
        _state = LifecycleState.suspended;
        _didSuspendController.add(this);
        _transitionFuture = null;
        completer.complete();
      });
    });

    return completer.future;
  }

  /// Public method to resume the module.
  ///
  /// This should put the module back into its normal state after the module
  /// was suspended.
  ///
  /// Only initiates the resume process when the module is in the suspended
  /// state. If the module is in the resuming state a warning is logged and the
  /// method is a noop. If the module is in any other state, a StateError is
  /// thrown.
  Future<Null> resume() {
    if (isLoaded || isResuming) {
      return _buildNoopResponse(
          isTransitioning: isResuming,
          methodName: 'resume',
          currentState:
              isResuming ? LifecycleState.resuming : LifecycleState.loaded);
    }

    if (!isSuspended) {
      return _buildIllegalTransitionResponse(
          reason:
              'Only a module in the ${LifecycleState.suspended} state can be '
              'resumed.');
    }

    _state = LifecycleState.resuming;
    final completer = new Completer<Null>();
    _transitionFuture = completer.future;
    _willResumeController.add(this);

    Future.wait(_childModules.map((c) => c.resume())).then((_) {
      onResume().then((_) {
        _state = LifecycleState.loaded;
        _didResumeController.add(this);
        _transitionFuture = null;
        completer.complete();
      });
    });

    return completer.future;
  }

  /// Public method to query the unloadable state of the Module.
  ///
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
  ///
  /// Calls shouldUnload(), and, if that completes successfully, continues to
  /// call onUnload() on the module and all registered child modules. If
  /// unloading is rejected, this method will complete with an error.
  ///
  /// Initiates the unload process when the module is in the loaded or suspended
  /// state. If the module is in the unloading or unloaded state a warning is
  /// logged and the method is a noop. If the module is in any other state, a
  /// StateError is thrown.
  Future<Null> unload() {
    if (isUnloaded || isUnloading) {
      return _buildNoopResponse(
          isTransitioning: isUnloading,
          methodName: 'unload',
          currentState:
              isUnloading ? LifecycleState.unloading : LifecycleState.unloaded);
    }

    if (!(isLoaded || isSuspended)) {
      return _buildIllegalTransitionResponse(
          targetState: LifecycleState.unloaded,
          allowedStates: [LifecycleState.loaded, LifecycleState.suspended]);
    }

    ShouldUnloadResult shouldUnloadResult = shouldUnload();
    if (!shouldUnloadResult.shouldUnload) {
      // reject with shouldUnload messages
      return new Future.error(new ModuleUnloadCanceledException(
          shouldUnloadResult.messagesAsString()));
    }

    _state = LifecycleState.unloading;
    final completer = new Completer<Null>();
    _transitionFuture = completer.future;
    _willUnloadController.add(this);

    final unloadChildren = _childModules.map((c) => c.unload());
    Future.wait(unloadChildren).then((_) {
      _childModules.clear();
      onUnload().then((_) {
        _disposableProxy.dispose().then((_) {
          _state = LifecycleState.unloaded;
          _didUnloadController
            ..add(this)
            ..close();
          _transitionFuture = null;
          completer.complete();
        });
      });
    });
    return completer.future;
  }

  //--------------------------------------------------------
  // Methods that can be optionally implemented by subclasses
  // to execute code during certain phases of the module
  // lifecycle
  //--------------------------------------------------------

  /// Custom logic to be executed during load.
  ///
  /// Initial data queries and interactions with the server can be triggered
  /// here.  Returns a future with no payload that completes when the module has
  /// finished loading.
  @protected
  Future onLoad() async {}

  /// Custom logic to be executed when a child module is to be loaded.
  @protected
  Future<Null> onWillLoadChildModule(LifecycleModule module) async {}

  /// Custom logic to be executed when a child module has been loaded.
  @protected
  Future<Null> onDidLoadChildModule(LifecycleModule module) async {}

  /// Custom logic to be executed when a child module is to be unloaded.
  @protected
  Future<Null> onWillUnloadChildModule(LifecycleModule module) async {}

  /// Custom logic to be executed when a child module has been unloaded.
  @protected
  Future<Null> onDidUnloadChildModule(LifecycleModule module) async {}

  /// Custom logic to be executed during suspend.
  ///
  /// Server connections can be dropped and large data structures unloaded here.
  /// Nothing should be done here that cannot be undone in [onResume].
  @protected
  Future<Null> onSuspend() async {}

  /// Custom logic to be executed during resume.
  ///
  /// Any changes made in [onSuspend] can be reverted here.
  @protected
  Future<Null> onResume() async {}

  /// Custom logic to be executed during shouldUnload (consequently also in unload).
  ///
  /// Returns a ShouldUnloadResult.
  /// [ShouldUnloadResult.shouldUnload == true] indicates that the module is safe to unload.
  /// [ShouldUnloadResult.shouldUnload == false] indicates that the module should not be unloaded.
  /// In this case, ShouldUnloadResult.messages contains a list of string messages indicating
  /// why unload was rejected.
  @protected
  ShouldUnloadResult onShouldUnload() {
    return new ShouldUnloadResult();
  }

  /// Custom logic to be executed during unload.
  ///
  /// Called on unload if shouldUnload completes with true. This can be used for
  /// cleanup. Returns a future with no payload that completes when the module
  /// has finished unloading.
  @protected
  Future<Null> onUnload() async {}

  /// Returns a new [Future] error with a constructed reason.
  Future<Null> _buildIllegalTransitionResponse(
      {LifecycleState targetState,
      Iterable<LifecycleState> allowedStates,
      String reason}) {
    reason = reason ??
        'Only a module in the '
        '${allowedStates.map(_readableStateName).join(", ")} states can '
        'transition to ${_readableStateName(targetState)}';
    return new Future.error(new StateError(
        'Transitioning from $_state to $targetState is not allowed. $reason'));
  }

  Future<Null> _buildNoopResponse(
      {@required String methodName,
      @required LifecycleState currentState,
      @required isTransitioning}) {
    _logger.warning('.$methodName() was called while Module "$name" is already '
        '${_readableStateName(currentState)}; this is a no-op. Check for any '
        'unnecessary calls to .$methodName().');

    return _transitionFuture ?? new Future.value(null);
  }

  /// Obtains the value of a [LifecycleState] enumeration.
  String _readableStateName(LifecycleState state) => '$state'.split('.')[1];
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
