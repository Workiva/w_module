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

@TestOn('vm || browser')
import 'dart:async';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart' show protected;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:w_common/disposable.dart';

import 'package:w_module/src/lifecycle_module.dart';

import 'utils.dart';

const String shouldUnloadError = 'Mock shouldUnload false message';

class MockStreamSubscription extends Mock implements StreamSubscription<Null> {}

class TestLifecycleModule extends LifecycleModule {
  Iterable<StreamSubscription<LifecycleModule>> _eventListStreamSubscriptions;
  bool _managedDisposerWasCalled = false;
  bool _getManagedDisposerWasCalled = false;

  final Disposable managedDisposable;
  ManagedDisposer managedDisposer;
  final StreamController<Null> managedStreamController;
  final MockStreamSubscription managedStreamSubscription;
  Error onDidLoadChildModuleError;
  Error onDidUnloadChildModuleError;
  Error onLoadError;
  Error onResumeError;
  Error onSuspendError;
  Error onUnloadError;
  Error onWillLoadChildModuleError;
  Error onWillUnloadChildModuleError;

  @override
  final String name;

  // mock data to be used for test validation
  List<String> eventList;
  bool mockShouldUnload;

  TestLifecycleModule({String name})
      : managedDisposable = new Disposable(),
        managedStreamController = new StreamController<Null>(),
        managedStreamSubscription = new MockStreamSubscription(),
        name = name ?? 'TestLifecycleModule' {
    // init test validation data
    eventList = [];
    mockShouldUnload = true;

    // Manage disposables
    managedDisposer = getManagedDisposer(() {
      _getManagedDisposerWasCalled = true;
    });
    manageDisposable(managedDisposable);
    manageDisposer(() {
      _managedDisposerWasCalled = true;
    });
    manageStreamController(managedStreamController);
    // ignore: deprecated_member_use
    manageStreamSubscription(managedStreamSubscription);

    var getEventListAdder =
        (String label) => (LifecycleModule _) => eventList.add(label);
    var onErrorHandler = (Object error) {};

    _eventListStreamSubscriptions = [
      // Parent module events:
      willLoad.listen(getEventListAdder('willLoad'), onError: onErrorHandler),
      didLoad.listen(getEventListAdder('didLoad'), onError: onErrorHandler),
      willUnload.listen(getEventListAdder('willUnload'),
          onError: onErrorHandler),
      didUnload.listen(getEventListAdder('didUnload'), onError: onErrorHandler),
      willSuspend.listen(getEventListAdder('willSuspend'),
          onError: onErrorHandler),
      didSuspend.listen(getEventListAdder('didSuspend'),
          onError: onErrorHandler),
      willResume.listen(getEventListAdder('willResume'),
          onError: onErrorHandler),
      didResume.listen(getEventListAdder('didResume'), onError: onErrorHandler),

      // Child module events:
      willLoadChildModule.listen(getEventListAdder('willLoadChildModule'),
          onError: onErrorHandler),
      didLoadChildModule.listen(getEventListAdder('didLoadChildModule'),
          onError: onErrorHandler),
      willUnloadChildModule.listen(getEventListAdder('willUnloadChildModule'),
          onError: onErrorHandler),
      didUnloadChildModule.listen(getEventListAdder('didUnloadChildModule'),
          onError: onErrorHandler),
    ];
  }

  bool get getManagedDisposerWasCalled => _getManagedDisposerWasCalled;

  bool get managedDisposerWasCalled => _managedDisposerWasCalled;

  // Overriding without re-applying the @protected annotation allows us to call
  // loadChildModule in our tests below.
  @override
  Future<Null> loadChildModule(LifecycleModule newModule) =>
      super.loadChildModule(newModule);

  @override
  @protected
  Future<Null> onWillLoadChildModule(LifecycleModule module) async {
    if (onWillLoadChildModuleError != null) {
      throw onWillLoadChildModuleError;
    }
    eventList.add('onWillLoadChildModule');
  }

  @override
  @protected
  Future<Null> onDidLoadChildModule(LifecycleModule module) async {
    if (onDidLoadChildModuleError != null) {
      throw onDidLoadChildModuleError;
    }
    eventList.add('onDidLoadChildModule');
  }

  @override
  @protected
  Future<Null> onWillUnloadChildModule(LifecycleModule module) async {
    if (onWillUnloadChildModuleError != null) {
      throw onWillUnloadChildModuleError;
    }
    eventList.add('onWillUnloadChildModule');
  }

  @override
  @protected
  Future<Null> onDidUnloadChildModule(LifecycleModule module) async {
    if (onDidUnloadChildModuleError != null) {
      throw onDidUnloadChildModuleError;
    }
    eventList.add('onDidUnloadChildModule');
  }

  @override
  @protected
  Future<Null> onLoad() async {
    await new Future.delayed(new Duration(milliseconds: 1));
    if (onLoadError != null) {
      throw onLoadError;
    }
    eventList.add('onLoad');
  }

  @override
  @protected
  ShouldUnloadResult onShouldUnload() {
    eventList.add('onShouldUnload');
    if (mockShouldUnload) {
      return new ShouldUnloadResult();
    } else {
      return new ShouldUnloadResult(false, shouldUnloadError);
    }
  }

  @override
  @protected
  Future<Null> onUnload() async {
    await new Future.delayed(new Duration(milliseconds: 1));
    if (onUnloadError != null) {
      throw onUnloadError;
    }
    eventList.add('onUnload');
  }

  @override
  @protected
  Future<Null> onSuspend() async {
    await new Future.delayed(new Duration(milliseconds: 1));
    if (onSuspendError != null) {
      throw onSuspendError;
    }
    eventList.add('onSuspend');
  }

  @override
  @protected
  Future<Null> onResume() async {
    await new Future.delayed(new Duration(milliseconds: 1));
    if (onResumeError != null) {
      throw onResumeError;
    }
    eventList.add('onResume');
  }

  /// Cancels subscriptions to the [TestLifecycleModule] lifecycle events.
  Future<Null> tearDown() async {
    await Future.wait(_eventListStreamSubscriptions
        .map((StreamSubscription sub) => sub.cancel()));
  }
}

void expectInLifecycleState(LifecycleModule module, LifecycleState state) {
  var isInState = false;
  switch (state) {
    case LifecycleState.instantiated:
      isInState = module.isInstantiated;
      break;
    case LifecycleState.loaded:
      isInState = module.isLoaded;
      break;
    case LifecycleState.loading:
      isInState = module.isLoading;
      break;
    case LifecycleState.resuming:
      isInState = module.isResuming;
      break;
    case LifecycleState.suspended:
      isInState = module.isSuspended;
      break;
    case LifecycleState.suspending:
      isInState = module.isSuspending;
      break;
    case LifecycleState.unloaded:
      isInState = module.isUnloaded;
      break;
    case LifecycleState.unloading:
      isInState = module.isUnloading;
      break;
  }
  expect(isInState, isTrue);
}

Future<Null> gotoState(LifecycleModule module, LifecycleState state) async {
  if (state == LifecycleState.instantiated) {
    return;
  }

  var future = module.load();
  if (state == LifecycleState.loading) {
    return;
  }
  await future;
  if (state == LifecycleState.loaded) {
    return;
  }

  future = module.suspend();
  if (state == LifecycleState.suspending) {
    return;
  }
  await future;
  if (state == LifecycleState.suspended) {
    return;
  }

  future = module.resume();
  if (state == LifecycleState.resuming) {
    return;
  }
  await future;

  future = module.unload();
  if (state == LifecycleState.unloading) {
    return;
  }
  await future;
}

Future<Null> executeStateTransition(
    LifecycleModule module, LifecycleState state) {
  switch (state) {
    case LifecycleState.loading:
      return module.load();
    case LifecycleState.suspending:
      return module.suspend();
    case LifecycleState.resuming:
      return module.resume();
    default: // LifecycleState.unloading:
      return module.unload();
  }
}

void main() {
  Logger.root.level = Level.ALL;
  final StateError testError = new StateError('You should have expected this');

  group('LifecycleModule', () {
    TestLifecycleModule module;

    setUp(() async {
      module = new TestLifecycleModule();
    });

    tearDown(() async {
      await module.tearDown();
    });

    void testInvalidTransitions(
        LifecycleState state, List<LifecycleState> invalidStates) {
      invalidStates.forEach((fromState) {
        test('should throw StateError when state is $fromState', () async {
          await gotoState(module, fromState);
          expectInLifecycleState(module, fromState);
          expect(executeStateTransition(module, state), throwsStateError);
        });
      });
    }

    group('load', () {
      var expectedLoadEvents = ['willLoad', 'onLoad', 'didLoad'];

      test('should trigger loading events and call onLoad', () async {
        await module.load();
        expect(module.eventList, equals(expectedLoadEvents));
      });

      test('should set isLoading', () async {
        expect(module.isLoading, isFalse);
        var future = module.load();
        expect(module.isLoading, isTrue);
        await future;
        expect(module.isLoading, isFalse);
      });

      test('should emit lifecycle log events', () async {
        expect(
            Logger.root.onRecord,
            emitsInOrder([
              logRecord(level: Level.FINE, message: equals('willLoad')),
              logRecord(level: Level.FINE, message: equals('didLoad')),
            ]));

        await module.load();
      });

      group('with an onLoad that throws', () {
        setUp(() {
          module.onLoadError = testError;
        });

        test('should return that error',
            () => expect(module.load(), throwsA(same(module.onLoadError))));

        test('should add that error to didLoad stream', () {
          module.didLoad.listen((LifecycleModule _) {},
              onError: expectAsync2((Error error, StackTrace stackTrace) {
            expect(error, same(module.onLoadError));
            expect(stackTrace, isNotNull);
          }));
          expect(module.load(), throwsA(same(module.onLoadError)));
        });
      });

      test('should set isLoaded', () async {
        expect(module.isLoaded, isFalse);
        await module.load();
        expect(module.isLoaded, isTrue);
      });

      test('should update module state', () async {
        expectInLifecycleState(module, LifecycleState.instantiated);
        var future = module.load();
        expectInLifecycleState(module, LifecycleState.loading);
        await future;
        expectInLifecycleState(module, LifecycleState.loaded);
      });

      test('should return pending future if it is already loading', () async {
        await gotoState(module, LifecycleState.loading);
        var future1 = module.load();
        var future2 = module.load();
        expect(future1, same(future2));
      });

      test('should return new future if load is called after module has loaded',
          () async {
        await gotoState(module, LifecycleState.loading);
        var future1 = module.load();
        await future1;
        var future2 = module.load();

        expect(future1, isNot(same(future2)));
      });

      test('should only load once if it is already loading', () async {
        var future = module.load();
        expect(module.isLoaded, isFalse);
        await Future.wait([module.load(), future]);
        expect(module.isLoaded, isTrue);
        expect(module.eventList, equals(expectedLoadEvents));
      });

      test('should warn if it is already loading', () async {
        await gotoState(module, LifecycleState.loading);
        expect(
            Logger.root.onRecord,
            emits(
                logRecord(level: Level.WARNING, message: contains('loading'))));

        await module.load();
      });

      test('should warn if it was already loaded', () async {
        await module.load();
        expect(
            Logger.root.onRecord,
            emits(
                logRecord(level: Level.WARNING, message: contains('loaded'))));

        await module.load();
      });

      testInvalidTransitions(LifecycleState.loading, [
        LifecycleState.suspending,
        LifecycleState.suspended,
        LifecycleState.resuming,
        LifecycleState.unloading,
        LifecycleState.unloaded
      ]);
    });

    group('unload', () {
      var expectedUnloadEvents = [
        'onShouldUnload',
        'willUnload',
        'onUnload',
        'didUnload'
      ];

      test('should dispatch events and call onShouldUnload and onUnload',
          () async {
        await gotoState(module, LifecycleState.loaded);
        module.eventList.clear();

        await module.unload();
        expect(module.eventList, equals(expectedUnloadEvents));
      });

      test('should unload after loading completes', () async {
        await gotoState(module, LifecycleState.loading);
        module.eventList.clear();
        await module.unload();
        expect(module.eventList,
            ['willLoad', 'onLoad', 'didLoad']..addAll(expectedUnloadEvents));
      });

      test('should unload after suspending completes', () async {
        await gotoState(module, LifecycleState.suspending);
        module.eventList.clear();
        await module.unload();
        expect(
            module.eventList,
            ['willSuspend', 'onSuspend', 'didSuspend']
              ..addAll(expectedUnloadEvents));
      });

      test('should unload after resuming completes', () async {
        await gotoState(module, LifecycleState.resuming);
        module.eventList.clear();
        await module.unload();
        expect(
            module.eventList,
            ['willResume', 'onResume', 'didResume']
              ..addAll(expectedUnloadEvents));
      });

      test('should emit lifecycle log events', () async {
        await gotoState(module, LifecycleState.loaded);
        expect(
            Logger.root.onRecord,
            emitsInOrder([
              logRecord(level: Level.FINE, message: equals('willUnload')),
              logRecord(level: Level.FINE, message: equals('didUnload')),
            ]));

        await module.unload();
      });

      group('with an onUnload that throws', () {
        setUp(() async {
          await gotoState(module, LifecycleState.loaded);
          module.eventList.clear();

          module.onUnloadError = testError;
        });

        test('should return that error',
            () => expect(module.unload(), throwsA(same(testError))));

        test('should add that error to didUnload stream', () {
          module.didUnload.listen((LifecycleModule _) {},
              onError: expectAsync2((Error error, StackTrace stackTrace) {
            expect(error, same(module.onUnloadError));
            expect(stackTrace, isNotNull);
          }));
          expect(module.unload(), throwsA(same(module.onUnloadError)));
        });
      });

      test('should set isUnloading', () async {
        await module.load();
        expect(module.isUnloading, isFalse);
        var future = module.unload();
        expect(module.isUnloading, isTrue);
        await future;
        expect(module.isUnloading, isFalse);
      });

      test('should set isUnloaded', () async {
        await module.load();
        expect(module.isUnloaded, isFalse);
        await module.unload();
        expect(module.isUnloaded, isTrue);
      });

      test('should update module state', () async {
        await module.load();
        expectInLifecycleState(module, LifecycleState.loaded);
        var future = module.unload();
        expectInLifecycleState(module, LifecycleState.unloading);
        await future;
        expectInLifecycleState(module, LifecycleState.unloaded);
      });

      test('should support unloading from suspended state', () async {
        await gotoState(module, LifecycleState.suspended);
        module.eventList.clear();
        expect(module.isSuspended, isTrue);
        expectInLifecycleState(module, LifecycleState.suspended);

        await module.unload();

        expect(module.isUnloaded, isTrue);
        expectInLifecycleState(module, LifecycleState.unloaded);
        expect(module.eventList, equals(expectedUnloadEvents));
      });

      test('should return pending future if it is already unloading', () async {
        await gotoState(module, LifecycleState.unloading);
        var future1 = module.unload();
        var future2 = module.unload();
        expect(future1, same(future2));
      });

      test(
          'should return new future if unload is called after module has unloaded',
          () async {
        await gotoState(module, LifecycleState.unloading);
        var future1 = module.unload();
        await future1;
        var future2 = module.unload();

        expect(future1, isNot(same(future2)));
      });

      test('should only unload once if it is already unloading', () async {
        await module.load();
        module.eventList.clear();
        var future = module.unload();
        expect(module.isUnloaded, isFalse);
        await Future.wait([module.unload(), future]);
        expect(module.isUnloaded, isTrue);
        expect(module.eventList, equals(expectedUnloadEvents));
      });

      test('should warn if it is already unloading', () async {
        await gotoState(module, LifecycleState.unloading);
        expect(
            Logger.root.onRecord,
            emits(logRecord(
                level: Level.WARNING, message: contains('unloading'))));
        await module.unload();
      });

      test('should warn if it was already unloaded', () async {
        await gotoState(module, LifecycleState.unloaded);
        expect(
            Logger.root.onRecord,
            emits(logRecord(
                level: Level.WARNING, message: contains('unloaded'))));
        await module.unload();
      });

      test('should throw an exception if shouldUnload completes false',
          () async {
        await module.load();
        module.eventList.clear();
        module.mockShouldUnload = false;
        var error;
        try {
          await module.unload();
        } on ModuleUnloadCanceledException catch (e) {
          error = e;
        }
        expect(error, isNotNull);
        expect(error.message, equals(shouldUnloadError));
        expect(module.eventList, equals(['onShouldUnload']));
        expect(module.isLoaded, isTrue);
      });

      test('should succeed on second attempt if shouldUnload completes true',
          () async {
        await module.load();
        module.eventList.clear();
        module.mockShouldUnload = false;
        var error;
        try {
          await module.unload();
        } on ModuleUnloadCanceledException catch (e) {
          error = e;
        }
        expect(error, isNotNull);
        expect(module.isLoaded, isTrue);

        module.mockShouldUnload = true;
        await module.unload();
        expect(module.isUnloaded, isTrue);
      });

      test(
          'should not dispatch willUnload or didUnload if shouldUnload completes false',
          () async {
        module.willUnload.listen(expectAsync1((_) {}, count: 0));
        module.didUnload.listen(expectAsync1((_) {}, count: 0));
        await module.load();
        module.eventList.clear();
        module.mockShouldUnload = false;
        try {
          await module.unload();
        } on ModuleUnloadCanceledException catch (_) {}
        expect(module.isLoaded, isTrue);
      });

      test('should dispose managed disposables', () async {
        await module.load();
        expect(module.managedDisposable.isDisposed, isFalse);
        expect(module.managedDisposerWasCalled, isFalse);
        expect(module.getManagedDisposerWasCalled, isFalse);
        expect(module.managedStreamController.isClosed, isFalse);
        verifyNever(module.managedStreamSubscription.cancel());

        var controller = new StreamController();
        controller.onCancel = expectAsync1(([_]) {}, count: 1);
        module.listenToStream(
            controller.stream, expectAsync1((_) {}, count: 0));

        await module.unload();
        expect(module.managedDisposable.isDisposed, isTrue);
        expect(module.managedDisposerWasCalled, isTrue);
        expect(module.getManagedDisposerWasCalled, isTrue);
        expect(module.managedStreamController.isClosed, isTrue);
        verify(module.managedStreamSubscription.cancel());
        controller.add(null);
        await controller.close();
      });
    });

    group('suspend', () {
      var expectedSuspendEvents = ['willSuspend', 'onSuspend', 'didSuspend'];

      test('should dispatch suspend events and call onSuspend', () async {
        await gotoState(module, LifecycleState.loaded);
        module.eventList.clear();
        await module.suspend();
        expect(module.eventList, equals(expectedSuspendEvents));
      });

      test('should suspend after loading completes', () async {
        await gotoState(module, LifecycleState.loading);
        module.eventList.clear();
        await module.suspend();
        expect(module.eventList,
            ['willLoad', 'onLoad', 'didLoad']..addAll(expectedSuspendEvents));
      });

      test('should suspend after resuming completes', () async {
        await gotoState(module, LifecycleState.resuming);
        module.eventList.clear();
        await module.suspend();
        expect(
            module.eventList,
            ['willResume', 'onResume', 'didResume']
              ..addAll(expectedSuspendEvents));
      });
      test('should emit lifecycle log events', () async {
        await gotoState(module, LifecycleState.loaded);
        expect(
            Logger.root.onRecord,
            emitsInOrder([
              logRecord(level: Level.FINE, message: equals('willSuspend')),
              logRecord(level: Level.FINE, message: equals('didSuspend')),
            ]));

        await module.suspend();
      });

      group('with an onSuspend that throws', () {
        setUp(() async {
          await gotoState(module, LifecycleState.loaded);
          module.onSuspendError = testError;
        });

        test('should return that error',
            () => expect(module.suspend(), throwsA(same(testError))));

        test('should add that error to didSuspend stream', () {
          module.didSuspend.listen((LifecycleModule _) {},
              onError: expectAsync2((Error error, StackTrace stackTrace) {
            expect(error, same(module.onSuspendError));
            expect(stackTrace, isNotNull);
          }));
          expect(module.suspend(), throwsA(same(module.onSuspendError)));
        });
      });

      test('should set isSuspending', () async {
        await module.load();
        expect(module.isSuspending, isFalse);
        var future = module.suspend();
        expect(module.isSuspending, isTrue);
        await future;
        expect(module.isSuspending, isFalse);
      });

      test('should set isSuspended', () async {
        await module.load();
        expect(module.isSuspended, isFalse);
        await module.suspend();
        expect(module.isSuspended, isTrue);
      });

      test('should update module state', () async {
        await module.load();
        expectInLifecycleState(module, LifecycleState.loaded);
        var future = module.suspend();
        expectInLifecycleState(module, LifecycleState.suspending);
        await future;
        expectInLifecycleState(module, LifecycleState.suspended);
      });

      test('should return pending future if it is already suspending',
          () async {
        await gotoState(module, LifecycleState.suspending);
        var future1 = module.suspend();
        var future2 = module.suspend();
        expect(future1, same(future2));
      });

      test(
          'should return new future if suspend is called after module has suspended',
          () async {
        await gotoState(module, LifecycleState.suspending);
        var future1 = module.suspend();
        await future1;
        var future2 = module.suspend();

        expect(future1, isNot(same(future2)));
      });

      test('should only suspend once if it is already suspending', () async {
        await module.load();
        module.eventList.clear();
        var future = module.suspend();
        expect(module.isSuspended, isFalse);
        await Future.wait([future, module.suspend()]);
        expect(module.isSuspended, isTrue);
        expect(module.eventList, equals(expectedSuspendEvents));
      });

      test('should warn if it is already suspending', () async {
        await gotoState(module, LifecycleState.suspending);
        expect(
            Logger.root.onRecord,
            emits(logRecord(
                level: Level.WARNING, message: contains('suspending'))));

        await module.suspend();
      });

      test('should warn if it is already suspended', () async {
        await gotoState(module, LifecycleState.suspended);
        expect(
            Logger.root.onRecord,
            emits(logRecord(
                level: Level.WARNING, message: contains('suspended'))));

        await module.suspend();
      });

      testInvalidTransitions(LifecycleState.suspending, [
        LifecycleState.instantiated,
        LifecycleState.unloading,
        LifecycleState.unloaded
      ]);
    });

    group('resume', () {
      var expectedResumeEvents = ['willResume', 'onResume', 'didResume'];

      test('should dispatch resume events and call onResume', () async {
        await gotoState(module, LifecycleState.suspended);
        module.eventList.clear();
        await module.resume();
        expect(module.eventList, equals(expectedResumeEvents));
      });

      test('should resume after suspending completes', () async {
        await gotoState(module, LifecycleState.suspending);
        module.eventList.clear();
        await module.resume();
        expect(
            module.eventList,
            ['willSuspend', 'onSuspend', 'didSuspend']
              ..addAll(expectedResumeEvents));
      });

      test('should emit lifecycle log events', () async {
        await gotoState(module, LifecycleState.suspended);
        expect(
            Logger.root.onRecord,
            emitsInOrder([
              logRecord(level: Level.FINE, message: equals('willResume')),
              logRecord(level: Level.FINE, message: equals('didResume')),
            ]));

        await module.resume();
      });

      group('with an onResume that throws', () {
        setUp(() async {
          await gotoState(module, LifecycleState.suspended);
          module.onResumeError = testError;
        });

        test('should return that error',
            () => expect(module.resume(), throwsA(same(module.onResumeError))));

        test('should add that error to didResume stream', () {
          module.didResume.listen((LifecycleModule _) {},
              onError: expectAsync2((Error error, StackTrace stackTrace) {
            expect(error, same(module.onResumeError));
            expect(stackTrace, isNotNull);
          }));
          expect(module.resume(), throwsA(same(module.onResumeError)));
        });
      });

      test('should set isResuming', () async {
        await gotoState(module, LifecycleState.suspended);
        expect(module.isResuming, isFalse);
        var future = module.resume();
        expect(module.isResuming, isTrue);
        await future;
        expect(module.isResuming, isFalse);
      });

      test('should set isLoaded', () async {
        await gotoState(module, LifecycleState.suspended);
        expect(module.isLoaded, isFalse);
        await module.resume();
        expect(module.isLoaded, isTrue);
      });

      test('should update module state', () async {
        await gotoState(module, LifecycleState.suspended);
        expectInLifecycleState(module, LifecycleState.suspended);
        var future = module.resume();
        expectInLifecycleState(module, LifecycleState.resuming);
        await future;
        expectInLifecycleState(module, LifecycleState.loaded);
      });

      test('should return pending future if it is already resuming', () async {
        await gotoState(module, LifecycleState.resuming);
        var future1 = module.resume();
        var future2 = module.resume();
        expect(future1, same(future2));
      });

      test(
          'should return new future if resume is called after module has resumed',
          () async {
        await gotoState(module, LifecycleState.resuming);
        var future1 = module.resume();
        await future1;
        var future2 = module.resume();

        expect(future1, isNot(same(future2)));
      });

      test('should only resume once if it is already resuming', () async {
        await gotoState(module, LifecycleState.suspended);
        module.eventList.clear();
        var future = module.resume();
        expect(module.isResuming, isTrue);
        await Future.wait([module.resume(), future]);
        expect(module.isResuming, isFalse);
        expect(module.isLoaded, isTrue);
        expect(module.eventList, equals(expectedResumeEvents));
      });

      test('should warn if it is already resuming', () async {
        await gotoState(module, LifecycleState.suspended);
        // ignore: unawaited_futures
        module.resume();

        expect(
            Logger.root.onRecord,
            emits(logRecord(
                level: Level.WARNING, message: contains('resuming'))));

        await module.resume();
      });

      test('should warn if it is already loaded', () async {
        await gotoState(module, LifecycleState.loaded);
        expect(
            Logger.root.onRecord,
            emits(
                logRecord(level: Level.WARNING, message: contains('loaded'))));

        await module.resume();
      });

      testInvalidTransitions(LifecycleState.resuming, [
        LifecycleState.instantiated,
        LifecycleState.loading,
        LifecycleState.unloading,
        LifecycleState.unloaded
      ]);
    });

    test('getManagedTimer should return a timer', () {
      module.getManagedTimer(
          new Duration(milliseconds: 10), expectAsync0(() {}));
    });

    test('getManagedPeriodicTimer should return a timer', () {
      var callCount = 0;
      module.getManagedPeriodicTimer(
          new Duration(milliseconds: 10),
          expectAsync1((Timer timer) {
            if (callCount++ >= 1) {
              timer.cancel();
            }
          }, count: 2));
    });
  }, timeout: new Timeout(new Duration(seconds: 2)));

  group('LifecycleModule with children', () {
    TestLifecycleModule childModule;
    TestLifecycleModule parentModule;

    setUp(() async {
      parentModule = new TestLifecycleModule(name: 'parent');
      childModule = new TestLifecycleModule(name: 'child');
      await parentModule.load();
    });

    tearDown(() async {
      await parentModule.tearDown();
      await childModule.tearDown();
    });

    group('loadChildModule', () {
      test('loads a child module', () async {
        parentModule.eventList.clear();
        await parentModule.loadChildModule(childModule);
        expect(
            parentModule.eventList,
            equals([
              'onWillLoadChildModule',
              'willLoadChildModule',
              'onDidLoadChildModule',
              'didLoadChildModule'
            ]));
        expect(
            childModule.eventList, equals(['willLoad', 'onLoad', 'didLoad']));
      });

      test('should emit lifecycle log events', () async {
        expect(
            Logger.root.onRecord,
            emitsInOrder([
              logRecord(
                level: Level.FINE,
                message: equals('willLoadChildModule'),
                loggerName: equals(parentModule.name),
              ),
              logRecord(
                level: Level.FINE,
                message: equals('willLoad'),
                loggerName: equals(childModule.name),
              ),
              logRecord(
                level: Level.FINE,
                message: equals('didLoad'),
                loggerName: equals(childModule.name),
              ),
              logRecord(
                level: Level.FINE,
                message: equals('didLoadChildModule'),
                loggerName: equals(parentModule.name),
              ),
            ]));

        await parentModule.loadChildModule(childModule);
      });

      group('with a child with an onLoad that throws', () {
        setUp(() {
          childModule.onLoadError = testError;
        });

        test(
            'should return the child error',
            () => expect(parentModule.loadChildModule(childModule),
                throwsA(same(childModule.onLoadError))));

        test('should add that error to didLoadChildModule stream', () {
          parentModule.didLoadChildModule.listen((LifecycleModule _) {},
              onError: expectAsync2((Error error, StackTrace stackTrace) {
            expect(error, same(childModule.onLoadError));
            expect(stackTrace, isNotNull);
          }));
          expect(parentModule.loadChildModule(childModule),
              throwsA(same(childModule.onLoadError)));
        });
      });

      group('with a parent with an onDidLoadChildModule that throws', () {
        setUp(() {
          parentModule.onDidLoadChildModuleError = testError;
        });

        test(
            'should return the parent error',
            () => expect(parentModule.loadChildModule(childModule),
                throwsA(same(parentModule.onDidLoadChildModuleError))));

        test('should add that error to didLoadChildModule stream', () {
          parentModule.didLoadChildModule.listen((LifecycleModule _) {},
              onError: expectAsync2((Error error, StackTrace stackTrace) {
            expect(error, same(parentModule.onDidLoadChildModuleError));
            expect(stackTrace, isNotNull);
          }));
          expect(parentModule.loadChildModule(childModule),
              throwsA(same(parentModule.onDidLoadChildModuleError)));
        });
      });

      group('with a parent with an onWillLoadChildModule that throws', () {
        setUp(() {
          parentModule.onWillLoadChildModuleError = testError;
        });

        test(
            'should return the parent error',
            () => expect(parentModule.loadChildModule(childModule),
                throwsA(same(parentModule.onWillLoadChildModuleError))));

        test('should add that error to willLoadChildModule stream', () {
          parentModule.willLoadChildModule.listen((LifecycleModule _) {},
              onError: expectAsync2((Error error, StackTrace stackTrace) {
            expect(error, same(parentModule.onWillLoadChildModuleError));
            expect(stackTrace, isNotNull);
          }));
          expect(parentModule.loadChildModule(childModule),
              throwsA(same(parentModule.onWillLoadChildModuleError)));
        });
      });
    });

    test('loadChildModule throws when parent module is unloaded', () async {
      await parentModule.unload();
      expect(parentModule.isUnloaded, isTrue);
      expect(parentModule.loadChildModule(childModule), throwsStateError);
    });

    test('loadChildModule throws when parent module is unloading', () {
      parentModule.unload();
      expect(parentModule.isUnloading, isTrue);
      expect(parentModule.loadChildModule(childModule), throwsStateError);
    });

    test('childModules returns an iterable of loaded child modules', () async {
      var childModuleB = new TestLifecycleModule();
      await parentModule.loadChildModule(childModule);
      await parentModule.loadChildModule(childModuleB);
      await new Future(() {});
      expect(parentModule.childModules,
          new isInstanceOf<Iterable<LifecycleModule>>());
      expect(parentModule.childModules.toList(),
          equals([childModule, childModuleB]));

      await childModuleB.tearDown();
    });

    group('suspend', () {
      setUp(() async {
        await parentModule.loadChildModule(childModule);
      });

      test('should suspend child modules', () async {
        parentModule.eventList.clear();
        childModule.eventList.clear();
        await parentModule.suspend();
        expect(parentModule.eventList,
            equals(['willSuspend', 'onSuspend', 'didSuspend']));
        expect(childModule.eventList,
            equals(['willSuspend', 'onSuspend', 'didSuspend']));
      });

      group('with a child with an onSuspend that throws', () {
        setUp(() {
          childModule.onSuspendError = testError;
        });

        test('should return the child error',
            () => expect(parentModule.suspend(), throwsA(same(testError))));

        test('should add the child error to didSuspend stream', () {
          parentModule.didSuspend.listen((LifecycleModule _) {},
              onError: expectAsync1((Error error) =>
                  expect(error, same(childModule.onSuspendError))));
          expect(parentModule.suspend(),
              throwsA(same(childModule.onSuspendError)));
        });

        test('should still suspend other children', () async {
          var secondChildModule = new TestLifecycleModule();
          await parentModule.loadChildModule(secondChildModule);
          try {
            await parentModule.suspend();
          } catch (_) {}
          expect(secondChildModule.isSuspended, isTrue);
        });
      });
    });

    group('resume', () {
      setUp(() async {
        await parentModule.loadChildModule(childModule);
        await parentModule.suspend();
      });

      test('should resume child modules', () async {
        parentModule.eventList.clear();
        childModule.eventList.clear();
        await parentModule.resume();
        expect(parentModule.eventList,
            equals(['willResume', 'onResume', 'didResume']));
        expect(childModule.eventList,
            equals(['willResume', 'onResume', 'didResume']));
      });

      group('with a child with an onResume that throws', () {
        setUp(() {
          childModule.onResumeError = testError;
        });

        test('should return the child error',
            () => expect(parentModule.resume(), throwsA(same(testError))));

        test('should add the child error to didResume stream', () {
          parentModule.didResume.listen((LifecycleModule _) {},
              onError: expectAsync1((Error error) =>
                  expect(error, same(childModule.onResumeError))));
          expect(
              parentModule.resume(), throwsA(same(childModule.onResumeError)));
        });

        test('should still resume other children', () async {
          var secondChildModule = new TestLifecycleModule();
          await parentModule.loadChildModule(secondChildModule);
          try {
            await parentModule.resume();
          } catch (_) {}
          expect(secondChildModule.isSuspended, isFalse);
        });
      });
    });

    group('unload', () {
      test('should unload child modules', () async {
        await parentModule.loadChildModule(childModule);
        parentModule.eventList.clear();
        childModule.eventList.clear();
        await parentModule.unload();
        expect(
            parentModule.eventList,
            equals([
              'onShouldUnload',
              'willUnload',
              'onWillUnloadChildModule',
              'willUnloadChildModule',
              'onDidUnloadChildModule',
              'didUnloadChildModule',
              'onUnload',
              'didUnload'
            ]));
        expect(
            childModule.eventList,
            equals([
              'onShouldUnload',
              'onShouldUnload',
              'willUnload',
              'onUnload',
              'didUnload'
            ]));
      });

      test('should emit lifecycle log events', () async {
        await parentModule.loadChildModule(childModule);
        expect(
            Logger.root.onRecord,
            emitsInOrder([
              logRecord(
                level: Level.FINE,
                message: equals('willUnload'),
                loggerName: equals(parentModule.name),
              ),
              logRecord(
                level: Level.FINE,
                message: equals('willUnload'),
                loggerName: equals(childModule.name),
              ),
              logRecord(
                level: Level.FINE,
                message: equals('willUnloadChildModule'),
                loggerName: equals(parentModule.name),
              ),
              logRecord(
                level: Level.FINE,
                message: equals('didUnload'),
                loggerName: equals(childModule.name),
              ),
              logRecord(
                level: Level.FINE,
                message: equals('didUnloadChildModule'),
                loggerName: equals(parentModule.name),
              ),
            ]));

        await parentModule.unload();
      });

      group('with a child with an onUnload that throws', () {
        setUp(() async {
          await parentModule.loadChildModule(childModule);
          childModule.onUnloadError = testError;
        });

        test(
            'should return the child error',
            () => expect(parentModule.unload(),
                throwsA(same(childModule.onUnloadError))));

        test('should add that error to didUnload stream', () {
          parentModule.didUnload.listen((LifecycleModule _) {},
              onError: expectAsync2((Error error, StackTrace stackTrace) {
            expect(error, same(childModule.onUnloadError));
            expect(stackTrace, isNotNull);
          }));
          expect(
              parentModule.unload(), throwsA(same(childModule.onUnloadError)));
        });

        test('should still unload other children', () async {
          var secondChildModule = new TestLifecycleModule();
          await parentModule.loadChildModule(secondChildModule);
          parentModule.didUnload.listen((LifecycleModule _) {},
              onError: expectAsync2((Error error, StackTrace stackTrace) {
            expect(error, same(childModule.onUnloadError));
            expect(stackTrace, isNotNull);
          }));
          try {
            await parentModule.unload();
          } catch (_) {}
          expect(secondChildModule.isUnloaded, isTrue);
        });
      });

      group('with a parent with an onWillUnloadChildModule that throws', () {
        setUp(() async {
          await parentModule.loadChildModule(childModule);
          parentModule.onWillUnloadChildModuleError = testError;
        });

        test('should add that error to willUnloadChildModule stream', () {
          parentModule.willUnloadChildModule.listen((LifecycleModule _) {},
              onError: expectAsync2((Error error, StackTrace stackTrace) {
            expect(error, same(parentModule.onWillUnloadChildModuleError));
            expect(stackTrace, isNotNull);
          }));
          parentModule.unload();
        });
      });

      group('with a parent with an onDidUnloadChildModule that throws', () {
        setUp(() async {
          await parentModule.loadChildModule(childModule);
          parentModule.onDidUnloadChildModuleError = testError;
        });

        test('should add that error to didUnloadChildModule stream', () {
          parentModule.didUnloadChildModule.listen((LifecycleModule _) {},
              onError: expectAsync2((Error error, StackTrace stackTrace) {
            expect(error, same(parentModule.onDidUnloadChildModuleError));
            expect(stackTrace, isNotNull);
          }));
          parentModule.unload();
        });
      });
    });

    test(
        'unloaded child module should be removed from lifecycle of parent module',
        () async {
      await parentModule.loadChildModule(childModule);
      parentModule.eventList.clear();
      childModule.eventList.clear();

      await childModule.unload();
      expect(childModule.eventList,
          equals(['onShouldUnload', 'willUnload', 'onUnload', 'didUnload']));
      await new Future(() {});
      expect(
          parentModule.eventList,
          equals([
            'onWillUnloadChildModule',
            'willUnloadChildModule',
            'onDidUnloadChildModule',
            'didUnloadChildModule'
          ]));
      parentModule.eventList.clear();
      childModule.eventList.clear();

      await parentModule.unload();
      expect(parentModule.eventList,
          equals(['onShouldUnload', 'willUnload', 'onUnload', 'didUnload']));
      expect(childModule.eventList, equals([]));
    });

    test('shouldUnload should reject if a child module rejects', () async {
      childModule.mockShouldUnload = false;
      ShouldUnloadResult parentShouldUnload = parentModule.shouldUnload();
      expect(parentShouldUnload.shouldUnload, equals(true));
      expect(parentShouldUnload.messages, equals([]));

      await parentModule.loadChildModule(childModule);
      parentModule.eventList.clear();
      childModule.eventList.clear();

      parentShouldUnload = parentModule.shouldUnload();
      expect(parentShouldUnload.shouldUnload, equals(false));
      expect(parentShouldUnload.messages, equals([shouldUnloadError]));
      expect(parentModule.eventList, equals(['onShouldUnload']));
      expect(childModule.eventList, equals(['onShouldUnload']));
    });

    test('shouldUnload should return parent and child rejection messages',
        () async {
      parentModule.mockShouldUnload = false;
      ShouldUnloadResult shouldUnloadRes = parentModule.shouldUnload();
      expect(shouldUnloadRes.shouldUnload, equals(false));
      expect(shouldUnloadRes.messages, equals([shouldUnloadError]));

      childModule.mockShouldUnload = false;
      shouldUnloadRes = childModule.shouldUnload();
      expect(shouldUnloadRes.shouldUnload, equals(false));
      expect(shouldUnloadRes.messages, equals([shouldUnloadError]));

      await parentModule.loadChildModule(childModule);
      parentModule.eventList.clear();
      childModule.eventList.clear();

      shouldUnloadRes = parentModule.shouldUnload();
      expect(shouldUnloadRes.shouldUnload, equals(false));
      expect(shouldUnloadRes.messages,
          equals([shouldUnloadError, shouldUnloadError]));
      expect(parentModule.eventList, equals(['onShouldUnload']));
      expect(childModule.eventList, equals(['onShouldUnload']));
    });
  }, timeout: new Timeout(new Duration(seconds: 2)));

  group('shouldUnloadResult', () {
    test('should default to a successful result with a blank message list',
        () async {
      ShouldUnloadResult result = new ShouldUnloadResult();
      expect(result.shouldUnload, equals(true));
      expect(result.messages, equals([]));
    });

    test('should support optional initial result and message', () async {
      ShouldUnloadResult result = new ShouldUnloadResult(false, 'mock message');
      expect(result.shouldUnload, equals(false));
      expect(result.messages, equals(['mock message']));
    });

    test('should return the boolean result on call', () async {
      ShouldUnloadResult result = new ShouldUnloadResult();
      expect(result(), equals(true));
    });

    test(
        'should return a newline delimited string of all messages in the list via messagesAsString',
        () async {
      ShouldUnloadResult result = new ShouldUnloadResult(false, 'mock message');
      result.messages.add('mock message 2');
      expect(result.messagesAsString(), equals('mock message\nmock message 2'));
    });
  });
}
