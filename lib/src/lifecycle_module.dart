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

library w_module.src.lifecycle_module;

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart'
    show mustCallSuper, protected, visibleForTesting;
import 'package:opentracing/opentracing.dart';
import 'package:w_common/disposable.dart';

import 'package:w_module/src/simple_module.dart';
import 'package:w_module/src/timing_specifiers.dart';

@visibleForTesting
Duration maxChildUnloadDuration = Duration(seconds: 30);

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
abstract class LifecycleModule extends SimpleModule with Disposable {
  static int _nextId = 0;
  // Used by tracing to tell apart multiple instances of the same module
  int _instanceId = _nextId++;

  List<LifecycleModule> _childModules = [];
  Logger? _memoLogger;
  Logger get _logger =>
      _memoLogger ??= Logger('w_module.LifecycleModule:$name');
  late String _defaultName;
  LifecycleState? _previousState;
  LifecycleState? _state = LifecycleState.instantiated;
  Completer<Null>? _transition;
  Span? _activeSpan;

  // Used by tracing to create a span if the consumer specifies when the module
  // reaches its first useful state
  DateTime? _startLoadTime;

  // Lifecycle event StreamControllers
  StreamController<LifecycleModule> _willLoadChildModuleController =
      StreamController<LifecycleModule>.broadcast();
  StreamController<LifecycleModule> _didLoadChildModuleController =
      StreamController<LifecycleModule>.broadcast();

  StreamController<LifecycleModule> _willLoadController =
      StreamController<LifecycleModule>.broadcast();
  StreamController<LifecycleModule> _didLoadController =
      StreamController<LifecycleModule>.broadcast();

  StreamController<LifecycleModule> _willSuspendController =
      StreamController<LifecycleModule>.broadcast();
  StreamController<LifecycleModule> _didSuspendController =
      StreamController<LifecycleModule>.broadcast();

  StreamController<LifecycleModule> _willResumeController =
      StreamController<LifecycleModule>.broadcast();
  StreamController<LifecycleModule> _didResumeController =
      StreamController<LifecycleModule>.broadcast();

  StreamController<LifecycleModule> _willUnloadChildModuleController =
      StreamController<LifecycleModule>.broadcast();
  StreamController<LifecycleModule> _didUnloadChildModuleController =
      StreamController<LifecycleModule>.broadcast();

  StreamController<LifecycleModule> _willUnloadController =
      StreamController<LifecycleModule>.broadcast();
  StreamController<LifecycleModule> _didUnloadController =
      StreamController<LifecycleModule>.broadcast();

  // constructor necessary to init load / unload state stream
  LifecycleModule() {
    [
      _willLoadController,
      _didLoadController,
      _willLoadChildModuleController,
      _didLoadChildModuleController,
      _willSuspendController,
      _didSuspendController,
      _willResumeController,
      _didResumeController,
      _willUnloadChildModuleController,
      _didUnloadChildModuleController,
      _willUnloadController,
      _didUnloadController,
    ].forEach(manageStreamController);

    <String, Stream>{
      'willLoad': willLoad,
      'didLoad': didLoad,
      'willLoadChildModule': willLoadChildModule,
      'didLoadChildModule': didLoadChildModule,
      'willSuspend': willSuspend,
      'didSuspend': didSuspend,
      'willResume': willResume,
      'didResume': didResume,
      'willUnloadChildModule': willUnloadChildModule,
      'didUnloadChildModule': didUnloadChildModule,
      'willUnload': willUnload,
      'didUnload': didUnload,
    }.forEach(_logLifecycleEvents);

    _defaultName = 'LifecycleModule($runtimeType)';

    getManagedDisposer(() async {
      _childModules.clear();
    });
  }

  /// If this module is in a transition state, this is the Span capturing the
  /// transition state.
  ///
  /// Example:
  ///
  /// ```dart
  /// @overide
  /// Future<Null> onLoad() {
  ///   var value = 'some_value;
  ///   ...
  ///   activeSpan.setTag('some.tag.name', value);
  ///   ...
  /// }
  /// ```
  @protected
  Span? get activeSpan => _activeSpan;

  /// Set internally by this module for the load span so it can be used as a
  /// `Reference` to other spans after the span is finished.
  SpanContext? _loadContext;

  /// Set internally by the parent module if this module is called by [loadChildModule]
  SpanContext? _parentContext;

  /// Builds a span that conditionally applies a followsFrom reference if this module
  /// was loaded by a parent module.
  ///
  /// Returns `null` if no globalTracer is configured, or if this module does
  /// not override the [name] getter (as the default name becomes nonsensical
  /// when compiled to js).
  Span? _startTransitionSpan(String operationName) {
    if (name == _defaultName) {
      return null;
    }

    final tracer = globalTracer();

    List<Reference> references = [];
    if (_parentContext != null) {
      references.add(Reference.followsFrom(_parentContext!));
    }

    return tracer.startSpan(
      '$name.$operationName',
      references: references,
      tags: _defaultTags,
    );
  }

  /// Creates a span with `globalTracer` from the start of [load] until now.
  ///
  /// This span is intended to represent the time it takes for the module to
  /// finish asynchronously loading any necessary data and entering a state which
  /// is ready for user interaction.
  ///
  /// Any [tags] or [references] specified will be added to this span.
  @protected
  void specifyFirstUsefulState({
    Map<String, dynamic> tags = const {},
    List<Reference> references = const [],
  }) =>
      specifyStartupTiming(
        StartupTimingType.firstUseful,
        tags: tags,
        references: references,
      );

  /// Creates a span with `globalTracer` from the start of [load] until now.
  ///
  /// The [specifier] indicates the purpose of this span.
  ///
  /// Any [tags] or [references] specified will be added to this span.
  @protected
  void specifyStartupTiming(
    StartupTimingType specifier, {
    Map<String, dynamic> tags = const {},
    List<Reference> references = const [],
  }) {
    // Load didn't start
    if (_loadContext == null || _startLoadTime == null) {
      throw StateError(
          'Calling `specifyStartupTiming` before calling `load()`');
    }

    final tracer = globalTracer();

    tracer
        .startSpan(
          '$name.${specifier.operationName}',
          references: [tracer.followsFrom(_loadContext!)]..addAll(references),
          startTime: _startLoadTime,
          tags: _defaultTags..addAll(tags),
        )
        ?.finish();

    _startLoadTime = null;
  }

  /// Name of the module for identification in exceptions and debug messages.
  // ignore: unnecessary_getters_setters
  String get name => _defaultName;

  Map<String, dynamic> get _defaultTags => {
        'span.kind': 'client',
        'module.instance_id': _instanceId,
      };

  /// Deprecated: the module name should be defined by overriding the getter in
  /// a subclass and it should not be mutable.
  @deprecated
  // ignore: unnecessary_getters_setters
  set name(String? newName) {
    if (newName != null) {
      _defaultName = newName;
    }
  }

  /// List of child components so that lifecycle can iterate over them as needed
  Iterable<LifecycleModule> get childModules => _childModules.toList();

  /// The [LifecycleModule] was loaded.
  ///
  /// Any error or exception thrown during the [LifecycleModule]'s
  /// [onLoad] call will be emitted.
  Stream<LifecycleModule> get didLoad => _didLoadController.stream;

  /// A child [LifecycleModule] was loaded.
  ///
  /// Any error or exception thrown during the child [LifecycleModule]'s
  /// [onLoad] call will be emitted.
  ///
  /// Any error or exception thrown during the parent [LifecycleModule]'s
  /// [onDidLoadChildModule] call will be emitted.
  Stream<LifecycleModule> get didLoadChildModule =>
      _didLoadChildModuleController.stream;

  /// The [LifecycleModule] was resumed.
  ///
  /// Any error or exception thrown during the child [LifecycleModule]'s
  /// [resume] call will be emitted.
  ///
  /// Any error or exception thrown during the [LifecycleModule]'s
  /// [onResume] call will be emitted.
  Stream<LifecycleModule> get didResume => _didResumeController.stream;

  /// The [LifecycleModule] was suspended.
  ///
  /// Any error or exception thrown during the child [LifecycleModule]'s
  /// [suspend] call will be emitted.
  ///
  /// Any error or exception thrown during the [LifecycleModule]'s
  /// [onSuspend] call will be emitted.
  Stream<LifecycleModule> get didSuspend => _didSuspendController.stream;

  /// The [LifecycleModule] was unloaded.
  ///
  /// Any error or exception thrown during the child [LifecycleModule]'s
  /// [unload] call will be emitted.
  ///
  /// Any error or exception thrown during the [LifecycleModule]'s
  /// [onUnload] call will be emitted.
  Stream<LifecycleModule> get didUnload => _didUnloadController.stream;

  /// A child [LifecycleModule] was unloaded.
  ///
  /// Any error or exception thrown during the child [LifecycleModule]'s
  /// [onUnload] call will be emitted.
  ///
  /// Any error or exception thrown during the parent [LifecycleModule]'s
  /// [onDidUnloadChildModule] call will be emitted.
  Stream<LifecycleModule> get didUnloadChildModule =>
      _didUnloadChildModuleController.stream;

  /// A child [LifecycleModule] is about to be loaded.
  ///
  /// Any error or exception thrown during the parent [LifecycleModule]'s
  /// [onDidLoadChildModule] call will be emitted.
  Stream<LifecycleModule> get willLoadChildModule =>
      _willLoadChildModuleController.stream;

  /// A child [LifecycleModule] is about to be unloaded.
  ///
  /// Any error or exception thrown during the parent [LifecycleModule]'s
  /// [onDidUnloadChildModule] call will be emitted.
  Stream<LifecycleModule> get willUnloadChildModule =>
      _willUnloadChildModuleController.stream;

  /// The [LifecycleModule] is about to be resumed.
  Stream<LifecycleModule> get willResume => _willResumeController.stream;

  /// The [LifecycleModule] is about to be unloaded.
  Stream<LifecycleModule> get willUnload => _willUnloadController.stream;

  /// The [LifecycleModule] is about to be loaded.
  Stream<LifecycleModule> get willLoad => _willLoadController.stream;

  /// The [LifecycleModule] is about to be suspended.
  Stream<LifecycleModule> get willSuspend => _willSuspendController.stream;

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

  /// Disposes this module and all its disposable dependencies.
  ///
  /// If the module has only been instantiated and has not yet started loading
  /// or been loaded, then this will immediately dispose of the module.
  ///
  /// If the module has already started loading, has loaded, or is in any other
  /// "loaded" state (suspending, suspended, resuming), then this will attempt
  /// to unload the module before disposing.
  ///
  /// If the module has already started unloading, this will wait for that
  /// transition before disposing.
  ///
  /// If the module has already started disposing or has disposed, then this
  /// will return the [Future] from [didDispose]. (An unloaded module will have
  /// already started or finished disposal).
  ///
  /// In any of these cases where an unload is attemped prior to disposal, a
  /// failure during unload will be caught and logged, but will not stop
  /// disposal. A module who cancels unload via [onShouldUnload] or who throws
  /// during [onUnload] will still be disposed.
  ///
  /// In short, calling [dispose] forces the disposal of this module regardless
  /// of its current state and regardless of its ability to unload successfully.
  ///
  /// If the modules unload is canceled or if an error is thrown during a
  /// lifecycle handler like onUnload as a part of this disposal process, they
  /// will still be available via their corresponding lifecycle event streams
  /// (e.g. [didUnload]).
  ///
  /// The [Future] returned from this method will resolve when disposal has
  /// completed and will only resolve with an error if one is thrown during
  /// [onDispose].
  @mustCallSuper
  @override
  Future<Null> dispose() => super.dispose();

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
  /// If an [Exception] is thrown during the call to [onLoad] it will be emitted
  /// on the [didLoad] lifecycle stream. The returned [Future] will also resolve
  /// with this exception.
  ///
  /// Note that [LifecycleModule] only supports one load/unload cycle. If [load]
  /// is called after a module has been unloaded, a [StateError] is thrown.
  Future<Null> load() {
    if (isOrWillBeDisposed) {
      return _buildDisposedOrDisposingResponse(methodName: 'load');
    }

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

    _activeSpan = _startTransitionSpan('load');
    _loadContext = _activeSpan?.context;
    _startLoadTime = _activeSpan?.startTime;

    _state = LifecycleState.loading;

    // Keep track of this load's completer
    final transition = Completer<Null>();

    // because this one can get overwritten
    _transition = transition;

    _load().then(transition.complete).catchError((error, trace) {
      transition.completeError(error, trace);
      _activeSpan?.setTag('error', true);
    }).whenComplete(() {
      _activeSpan?.finish();
      _activeSpan = null;
    });

    return transition.future;
  }

  /// Public method to async load a child module and register it
  /// for lifecycle management.
  ///
  /// If an [Exception] is thrown during the call to the parent
  /// [onWillLoadChildModule] it will be emitted on the [willLoadChildModule]
  /// lifecycle stream. The returned [Future] will also resolve with this
  /// exception.
  ///
  /// If an [Exception] is thrown during the call to the child [onLoad] it will
  /// be emitted on the [didLoadChildModule] lifecycle stream. The returned
  /// [Future] will also resolve with this exception.
  ///
  /// If an [Exception] is thrown during the call to the parent
  /// [onDidLoadChildModule] it will be emitted on the [didLoadChildModule]
  /// lifecycle stream. The returned [Future] will also resolve with this
  /// exception.
  ///
  /// Attempting to load a child module after a module has been unloaded will
  /// throw a [StateError].
  @protected
  Future<Null> loadChildModule(LifecycleModule? childModule) {
    if (isOrWillBeDisposed) {
      return _buildDisposedOrDisposingResponse(methodName: 'loadChildModule');
    }

    if (childModule == null || _childModules.contains(childModule)) {
      return Future.value(null);
    }

    if (isUnloaded || isUnloading) {
      var stateLabel = isUnloaded ? 'unloaded' : 'unloading';
      return Future.error(
          StateError('Cannot load child module when module is $stateLabel'),
          StackTrace.current);
    }

    final completer = Completer<Null>();
    onWillLoadChildModule(childModule).then((_) async {
      // It is possible to reach this point due to the asynchrony of onWillLoadChildModule.
      // In that case, simply do not load the child module and instead dispose it.
      if (isUnloaded || isUnloading) {
        await childModule.dispose();
        completer.complete();
        return;
      }

      _willLoadChildModuleController.add(childModule);

      final childModuleWillUnloadSub = listenToStream(
          childModule.willUnload, _onChildModuleWillUnload,
          onError: _willUnloadChildModuleController.addError);
      final childModuleDidUnloadSub = listenToStream(
          childModule.didUnload, _onChildModuleDidUnload,
          onError: (error, stackTrace) =>
              _didUnloadChildModuleController.addError);

      // The child module may not reach an unloaded state successfully, but
      // should always eventually be disposed. For this reason, we listen for
      // its disposal before removing it from the list of child modules.
      // ignore: unawaited_futures
      childModule.didDispose.then((_) {
        _childModules.remove(childModule);
      });

      try {
        manageDisposable(childModule);
        _childModules.add(childModule);
        childModule.parentContext = _loadContext;

        await childModule.load();
        try {
          await onDidLoadChildModule(childModule);
        } catch (error, stackTrace) {
          _logger.severe(
            'Exception in onDidLoadChildModule ($name)',
            error,
            stackTrace,
          );
          rethrow;
        }
        _didLoadChildModuleController.add(childModule);
        completer.complete();
      } catch (error, stackTrace) {
        // If the child module failed to load, we can dispose of it and cleanup
        // any state/subscriptions related to it.
        _childModules.remove(childModule);
        await childModule.dispose();
        await childModuleWillUnloadSub.cancel();
        await childModuleDidUnloadSub.cancel();

        _didLoadChildModuleController.addError(error, stackTrace);
        completer.completeError(error, stackTrace);
      } finally {
        childModule.parentContext = null;
      }
    }).catchError((Object error, StackTrace stackTrace) {
      _logger.severe(
        'Exception in onWillLoadChildModule ($name)',
        error,
        stackTrace,
      );
      _willLoadChildModuleController.addError(error, stackTrace);
      completer.completeError(error, stackTrace);
    });

    return completer.future;
  }

  /// Provide a way for a module to update its children's parentContext that is compatible with mocking in 2.19.
  ///
  /// This is only intended for use within this file and is marked protected.
  @protected
  set parentContext(SpanContext? context) => _parentContext = context;

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
  ///
  /// The [Future] values of all children [suspend] calls will be awaited. The
  /// first child to return an error value will emit the error on the
  /// [didSuspend] lifecycle stream. The returned [Future] will also resolve
  /// with this exception.
  ///
  /// If an [Exception] is thrown during the call to [onSuspend] it will be
  /// emitted on the [didSuspend] lifecycle stream. The returned [Future] will
  /// also resolve with this exception.
  ///
  /// If an error or exception is thrown during the call to the parent
  /// [onSuspend] lifecycle method it will be emitted on the [didSuspend]
  /// lifecycle stream. The error will also be returned by [suspend].
  Future<Null> suspend() {
    if (isOrWillBeDisposed) {
      return _buildDisposedOrDisposingResponse(methodName: 'suspend');
    }

    if (isSuspended || isSuspending) {
      return _buildNoopResponse(
          isTransitioning: isSuspending,
          methodName: 'suspend',
          currentState: isSuspending
              ? LifecycleState.suspending
              : LifecycleState.suspended);
    }

    if (!(isLoaded || isLoading || isResuming)) {
      return _buildIllegalTransitionResponse(
          targetState: LifecycleState.suspended,
          allowedStates: [
            LifecycleState.loaded,
            LifecycleState.loading,
            LifecycleState.resuming
          ]);
    }

    Future<Null>? pendingTransition;
    if (_transition != null && !_transition!.isCompleted) {
      pendingTransition = _transition!.future.then((_) {
        _activeSpan = _startTransitionSpan('suspend');
      });
    } else {
      _activeSpan = _startTransitionSpan('suspend');
    }

    final transition = Completer<Null>();
    _transition = transition;
    _state = LifecycleState.suspending;

    _suspend(pendingTransition)
        .then(transition.complete)
        .catchError((error, trace) {
      transition.completeError(error, trace);
      _activeSpan?.setTag('error', true);
    }).whenComplete(() {
      _activeSpan?.finish();
      _activeSpan = null;
    });

    return transition.future;
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
  ///
  /// The [Future] values of all children [resume] calls will be awaited. The
  /// first child to return an error value will emit the error on the
  /// [didResume] lifecycle stream. The returned [Future] will also resolve with
  /// this exception.
  ///
  /// If an [Exception] is thrown during the call to [onResume] it will be
  /// emitted on the [didResume] lifecycle stream. The returned [Future] will
  /// also resolve with this exception.
  ///
  /// If an error or exception is thrown during the call to the parent
  /// [onResume] lifecycle method it will be emitted on the [didResume]
  /// lifecycle stream. The error will also be returned by [resume].
  Future<Null> resume() {
    if (isOrWillBeDisposed) {
      return _buildDisposedOrDisposingResponse(methodName: 'resume');
    }

    if (isLoaded || isResuming) {
      return _buildNoopResponse(
          isTransitioning: isResuming,
          methodName: 'resume',
          currentState:
              isResuming ? LifecycleState.resuming : LifecycleState.loaded);
    }

    if (!(isSuspended || isSuspending)) {
      return _buildIllegalTransitionResponse(
          targetState: LifecycleState.loaded,
          allowedStates: [LifecycleState.suspended, LifecycleState.suspending]);
    }

    Future<Null>? pendingTransition;
    if (_transition != null && !_transition!.isCompleted) {
      pendingTransition = _transition!.future.then((_) {
        _activeSpan = _startTransitionSpan('resume');
      });
    } else {
      _activeSpan = _startTransitionSpan('resume');
    }

    _state = LifecycleState.resuming;
    final transition = Completer<Null>();
    _transition = transition;

    _resume(pendingTransition)
        .then(transition.complete)
        .catchError((error, trace) {
      transition.completeError(error, trace);
      _activeSpan?.setTag('error', true);
    }).whenComplete(() {
      _activeSpan?.finish();
      _activeSpan = null;
    });

    return _transition!.future;
  }

  /// Public method to query the unloadable state of the Module.
  ///
  /// Calls the onShouldUnload() method, which can be implemented on a Module.
  /// onShouldUnload is also called on all registered child modules.
  ShouldUnloadResult shouldUnload() {
    // collect results from all child modules and self
    List<ShouldUnloadResult> shouldUnloads = [];
    for (var child in _childModules) {
      if (child.isUnloading || child.isUnloaded || child.isOrWillBeDisposed) {
        continue;
      }
      shouldUnloads.add(child.shouldUnload());
    }
    shouldUnloads.add(onShouldUnload());

    // aggregate into 1 combined result
    ShouldUnloadResult finalResult = ShouldUnloadResult();
    for (var result in shouldUnloads) {
      if (!result.shouldUnload) {
        finalResult.shouldUnload = false;
        finalResult.messages.addAll(result.messages);
      }
    }
    return finalResult;
  }

  /// Public method to trigger the Module unload cycle.
  ///
  /// Calls shouldUnload(), and, if that completes successfully, continues to
  /// call onUnload() on the module and all registered child modules. If
  /// unloading is rejected, this method will complete with an error. The rejection
  /// error will not be added to the [didUnload] lifecycle event stream.
  ///
  /// Initiates the unload process when the module is in the loaded or suspended
  /// state. If the module is in the unloading or unloaded state a warning is
  /// logged and the method is a noop. If the module is in any other state, a
  /// StateError is thrown.
  ///
  /// The [Future] values of all children [unload] calls will be awaited. The
  /// first child to return an error value will emit the error on the
  /// [didUnload] lifecycle stream. The returned [Future] will also resolve with
  /// this exception.
  ///
  /// If an [Exception] is thrown during the call to [onUnload] it will be
  /// emitted on the [didUnload] lifecycle stream. The returned [Future] will
  /// also resolve with this exception.
  ///
  /// If an error or exception is thrown during the call to the parent
  /// [onUnload] lifecycle method it will be emitted on the [didUnload]
  /// lifecycle stream. The error will also be returned by [unload].
  ///
  /// If the unload succeeds (i.e. is not canceled via [onShouldUnload] and is
  /// not prevented by an uncaught exception in [onUnload]), then this module
  /// will also be disposed. The [Future] returned by this method will resolve
  /// once unload _and_ disposal have completed.
  Future<Null> unload() {
    if (isUnloaded || isUnloading) {
      return _buildNoopResponse(
          isTransitioning: isUnloading,
          methodName: 'unload',
          currentState:
              isUnloading ? LifecycleState.unloading : LifecycleState.unloaded);
    }

    if (isOrWillBeDisposed) {
      return _buildDisposedOrDisposingResponse(methodName: 'unload');
    }

    if (!(isLoaded || isLoading || isResuming || isSuspended || isSuspending)) {
      return _buildIllegalTransitionResponse(
          targetState: LifecycleState.unloaded,
          allowedStates: [
            LifecycleState.loaded,
            LifecycleState.loading,
            LifecycleState.resuming,
            LifecycleState.suspended,
            LifecycleState.suspending
          ]);
    }

    Future? pendingTransition;
    if (_transition != null && !_transition!.isCompleted) {
      pendingTransition = _transition!.future;
    }

    _previousState = _state;
    _state = LifecycleState.unloading;
    final transition = Completer<Null>();
    _transition = transition;

    var unloadAndDispose = Completer<Null>();
    unloadAndDispose.complete(transition.future.then(((_) => dispose())));
    transition
        .complete(_unload(pendingTransition?.then((value) => value as Null)));
    return unloadAndDispose.future;
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
  Future<void> onResume() async {}

  /// Custom logic to be executed during shouldUnload (consequently also in unload).
  ///
  /// Returns a ShouldUnloadResult.
  /// [ShouldUnloadResult.shouldUnload == true] indicates that the module is safe to unload.
  /// [ShouldUnloadResult.shouldUnload == false] indicates that the module should not be unloaded.
  /// In this case, ShouldUnloadResult.messages contains a list of string messages indicating
  /// why unload was rejected.
  @protected
  ShouldUnloadResult onShouldUnload() {
    return ShouldUnloadResult();
  }

  /// Custom logic to be executed during unload.
  ///
  /// Called on unload if shouldUnload completes with true. This can be used for
  /// cleanup. Returns a future with no payload that completes when the module
  /// has finished unloading.
  @protected
  Future<Null> onUnload() async {}

  @mustCallSuper
  @override
  @protected
  Future<Null> onWillDispose() async {
    if (isInstantiated || isUnloaded) {
      return;
    }

    try {
      Future<Null> unloadingTransitionFuture;
      if (isUnloading) {
        unloadingTransitionFuture = _transition!.future;
      } else {
        Future? pendingTransition;
        if (_transition != null && !_transition!.isCompleted) {
          pendingTransition = _transition?.future;
        }
        _previousState = _state;
        _state = LifecycleState.unloading;
        unloadingTransitionFuture =
            _unload(pendingTransition?.then((value) => value as Null));
      }
      await unloadingTransitionFuture;
    } on ModuleUnloadCanceledException {
      // The unload was canceled, but disposal cannot be canceled. Log a warning
      // indicating this and continue with disposal.
      _logger.warning(
          '.dispose() was called but Module "$name" canceled its '
          'unload. The module will still be disposed.',
          null,
          StackTrace.current);
    } catch (error, stackTrace) {
      // An unexpected exception was thrown during unload. It will be emitted
      // as an error on the didUnload stream, but we will also log a warning
      // here explaining that disposal will still continue.
      _logger.warning(
          '.dispose() was called but Module "$name" threw an exception on '
          'unload. The module will still be disposed.',
          error,
          stackTrace);
    }
  }

  Future<Null> _buildDisposedOrDisposingResponse({required String methodName}) {
    _logger.warning('.$methodName() was called after Module "$name" had '
        // ignore: deprecated_member_use
        'already ${isOrWillBeDisposed ? 'started disposing' : 'disposed'}.');
    return Future.error(
        StateError(
            'Calling .$methodName() after disposal has started is not allowed.'),
        StackTrace.current);
  }

  /// Returns a new [Future] error with a constructed reason.
  Future<Null> _buildIllegalTransitionResponse(
      {LifecycleState? targetState,
      Iterable<LifecycleState>? allowedStates,
      String? reason}) {
    reason = reason ??
        'Only a module in the '
            '${allowedStates!.map(_readableStateName).join(", ")} states can '
            'transition to ${_readableStateName(targetState)}';
    return Future.error(
        StateError(
            'Transitioning from $_state to $targetState is not allowed. $reason'),
        StackTrace.current);
  }

  Future<Null> _buildNoopResponse(
      {required String methodName,
      required LifecycleState currentState,
      required isTransitioning}) {
    _logger.config(
        '.$methodName() was called while Module "$name" is already '
        '${_readableStateName(currentState)}; this is a no-op. Check for any '
        'unnecessary calls to .$methodName().',
        null,
        StackTrace.current);

    return _transition?.future ?? Future.value(null);
  }

  Future<Null> _load() async {
    try {
      _willLoadController.add(this);
      try {
        await onLoad();
      } catch (error, stackTrace) {
        _logger.severe(
          'Exception in onLoad ($name)',
          error,
          stackTrace,
        );
        rethrow;
      }
      if (_state == LifecycleState.loading) {
        _state = LifecycleState.loaded;
        _transition = null;
      }
      _didLoadController.add(this);
    } catch (error, stackTrace) {
      _didLoadController.addError(error, stackTrace);
      rethrow;
    }
  }

  /// A utility to logging LifecycleModule lifecycle events
  void _logLifecycleEvents(
      String logLabel, Stream<dynamic> lifecycleEventStream) {
    listenToStream(
        lifecycleEventStream, (dynamic _) => _logger.finest(logLabel),
        onError: (error, stackTrace) =>
            _logger.warning('$logLabel error: $error', error, stackTrace));
  }

  /// Handles a child [LifecycleModule]'s [didUnload] event.
  Future<Null> _onChildModuleDidUnload(LifecycleModule module) async {
    try {
      try {
        await onDidUnloadChildModule(module);
      } catch (error, stackTrace) {
        _logger.severe(
          'Exception in onDidUnloadChildModule ($name)',
          error,
          stackTrace,
        );
        rethrow;
      }
      _didUnloadChildModuleController.add(module);
    } catch (error, stackTrace) {
      _didUnloadChildModuleController.addError(error, stackTrace);
    }
  }

  /// Handles a child [LifecycleModule]'s [willUnload] event.
  Future<Null> _onChildModuleWillUnload(LifecycleModule module) async {
    try {
      try {
        await onWillUnloadChildModule(module);
      } catch (error, stackTrace) {
        _logger.severe(
          'Exception in onWillUnloadChildModule ($name)',
          error,
          stackTrace,
        );
        rethrow;
      }
      _willUnloadChildModuleController.add(module);
    } catch (error, stackTrace) {
      _willUnloadChildModuleController.addError(error, stackTrace);
    }
  }

  /// Obtains the value of a [LifecycleState] enumeration.
  String _readableStateName(LifecycleState? state) => '$state'.split('.')[1];

  Future<Null> _resume(Future<Null>? pendingTransition) async {
    try {
      if (pendingTransition != null) {
        await pendingTransition;
      }
      _willResumeController.add(this);
      List<Future<Null>> childResumeFutures = <Future<Null>>[];
      for (var child in _childModules.toList()) {
        childResumeFutures.add(Future.sync(() {
          child.parentContext = _activeSpan?.context;
          return child.resume().whenComplete(() {
            child.parentContext = null;
          });
        }));
      }
      await Future.wait(childResumeFutures);
      try {
        await onResume();
      } catch (error, stackTrace) {
        _logger.severe(
          'Exception in onResume ($name)',
          error,
          stackTrace,
        );
        rethrow;
      }
      if (_state == LifecycleState.resuming) {
        _state = LifecycleState.loaded;
        _transition = null;
      }
      _didResumeController.add(this);
    } catch (error, stackTrace) {
      _didResumeController.addError(error, stackTrace);
      rethrow;
    }
  }

  Future<Null> _suspend(Future<Null>? pendingTransition) async {
    try {
      if (pendingTransition != null) {
        await pendingTransition;
      }
      _willSuspendController.add(this);
      List<Future<Null>> childSuspendFutures = <Future<Null>>[];
      for (var child in _childModules.toList()) {
        childSuspendFutures.add(Future.sync(() async {
          child.parentContext = _activeSpan?.context;
          return child.suspend().whenComplete(() {
            child.parentContext = null;
          });
        }));
      }
      await Future.wait(childSuspendFutures);
      try {
        await onSuspend();
      } catch (error, stackTrace) {
        _logger.severe(
          'Exception in onSuspend ($name)',
          error,
          stackTrace,
        );
        rethrow;
      }
      if (_state == LifecycleState.suspending) {
        _state = LifecycleState.suspended;
        _transition = null;
      }
      _didSuspendController.add(this);
    } catch (error, stackTrace) {
      _didSuspendController.addError(error, stackTrace);
      rethrow;
    }
  }

  Future<Null> _unload(Future<Null>? pendingTransition) async {
    try {
      if (pendingTransition != null) {
        await pendingTransition;
      }

      final shouldUnloadResult = shouldUnload();
      if (!shouldUnloadResult.shouldUnload) {
        _state = _previousState;
        _previousState = null;
        _transition = null;
        // reject with shouldUnload messages
        throw ModuleUnloadCanceledException(
            shouldUnloadResult.messagesAsString());
      }

      _activeSpan = _startTransitionSpan('unload');

      _willUnloadController.add(this);
      await Future.wait(_childModules.toList().map((child) {
        child.parentContext = _activeSpan?.context;
        return child.unload().timeout(maxChildUnloadDuration, onTimeout: () {
          _logger.warning(
              'Child module may be stuck unloading: ${child.disposableTypeName}');
        }).whenComplete(() {
          child.parentContext = null;
        });
      }));
      try {
        await onUnload();
      } catch (error, stackTrace) {
        _logger.severe('Exception in onUnload ($name)', error, stackTrace);
        rethrow;
      }
      if (_state == LifecycleState.unloading) {
        _state = LifecycleState.unloaded;
        _previousState = null;
        _transition = null;
      }
      _didUnloadController.add(this);
    } on ModuleUnloadCanceledException catch (error, _) {
      // In the event of a cancellation, rethrow the exception and allow the
      // caller (either unload() or onWillDispose()) to handle it.
      rethrow;
    } catch (error, stackTrace) {
      // In the event of a failed unload (the module threw an exception but did
      // not explicitly cancel the unload), emit the unload failure event and
      // then rethrow the exception so that the caller (either unload() or
      // onWillDispose()) can handle it.
      _didUnloadController.addError(error, stackTrace);
      _activeSpan?.setTag('error', true);
      rethrow;
    } finally {
      _activeSpan?.finish();
      _activeSpan = null;
    }
  }
}

/// Exception thrown when unload fails.
class ModuleUnloadCanceledException implements Exception {
  String message;

  ModuleUnloadCanceledException(this.message);
}

/// A set of messages returned from the hierarchical application of shouldUnload
class ShouldUnloadResult {
  bool shouldUnload;
  List<String> messages = [];

  ShouldUnloadResult([this.shouldUnload = true, String? message]) {
    if (message != null) {
      messages.add(message);
    }
  }

  bool call() => shouldUnload;

  String messagesAsString() {
    return messages.join('\n');
  }
}
