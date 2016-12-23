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

@TestOn('vm || browser')
import 'dart:async';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart' show protected;
import 'package:test/test.dart';
import 'package:w_module/w_module.dart';

const String shouldUnloadError = 'Mock shouldUnload false message';

class TestLifecycleModule extends LifecycleModule {
  @override
  final String name = 'TestLifecycleModule';

  // mock data to be used for test validation
  List<String> eventList;
  bool mockShouldUnload;

  TestLifecycleModule() {
    // init test validation data
    eventList = [];
    mockShouldUnload = true;

    // Parent module events:
    willLoad.listen((_) {
      eventList.add('willLoad');
    });
    didLoad.listen((_) {
      eventList.add('didLoad');
    });
    willUnload.listen((_) {
      eventList.add('willUnload');
    });
    didUnload.listen((_) {
      eventList.add('didUnload');
    });
    willSuspend.listen((_) {
      eventList.add('willSuspend');
    });
    didSuspend.listen((_) {
      eventList.add('didSuspend');
    });
    willResume.listen((_) {
      eventList.add('willResume');
    });
    didResume.listen((_) {
      eventList.add('didResume');
    });
    didDispose.then((_) {
      eventList.add('didDispose');
    });

    // Child module events:
    willLoadChildModule.listen((_) {
      eventList.add('willLoadChildModule');
    });
    didLoadChildModule.listen((_) {
      eventList.add('didLoadChildModule');
    });
    willUnloadChildModule.listen((_) {
      eventList.add('willUnloadChildModule');
    });
    didUnloadChildModule.listen((_) {
      eventList.add('didUnloadChildModule');
    });
  }

  // Overriding without re-applying the @protected annotation allows us to call
  // loadChildModule in our tests below.
  @override
  Future<Null> loadChildModule(LifecycleModule newModule) =>
      super.loadChildModule(newModule);

  @override
  @protected
  Future<Null> onWillLoadChildModule(LifecycleModule module) async {
    eventList.add('onWillLoadChildModule');
  }

  @override
  @protected
  Future<Null> onDidLoadChildModule(LifecycleModule module) async {
    eventList.add('onDidLoadChildModule');
  }

  @override
  @protected
  Future<Null> onWillUnloadChildModule(LifecycleModule module) async {
    eventList.add('onWillUnloadChildModule');
  }

  @override
  @protected
  Future<Null> onDidUnloadChildModule(LifecycleModule module) async {
    eventList.add('onDidUnloadChildModule');
  }

  @override
  @protected
  Future<Null> onLoad() async {
    await new Future.delayed(new Duration(milliseconds: 1));
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
    eventList.add('onUnload');
  }

  @override
  @protected
  Future<Null> onSuspend() async {
    await new Future.delayed(new Duration(milliseconds: 1));
    eventList.add('onSuspend');
  }

  @override
  @protected
  Future<Null> onResume() async {
    await new Future.delayed(new Duration(milliseconds: 1));
    eventList.add('onResume');
  }

  @override
  @protected
  Future<Null> onDispose() async {
    await new Future.delayed(new Duration(milliseconds: 1));
    eventList.add('onDispose');
  }
}

Future<Null> gotoState(LifecycleModule module, LifecycleState state) async {
  if (state == LifecycleState.initialized) {
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

  LogRecord lastLogMessage;
  Logger.root.onRecord.listen((LogRecord message) {
    lastLogMessage = message;
  });

  group('LifecycleModule', () {
    TestLifecycleModule module;

    setUp(() {
      module = new TestLifecycleModule();
      lastLogMessage = null;
    });

    void testInvalidTransitions(
        LifecycleState state, List<LifecycleState> invalidStates) {
      invalidStates.forEach((fromState) {
        test('should throw StateError when state is $fromState', () async {
          await gotoState(module, fromState);
          expect(module.state, fromState);
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

      test('should set isLoaded', () async {
        expect(module.isLoaded, isFalse);
        await module.load();
        expect(module.isLoaded, isTrue);
      });

      test('should update module state', () async {
        expect(module.state, equals(LifecycleState.initialized));
        var future = module.load();
        expect(module.state, equals(LifecycleState.loading));
        await future;
        expect(module.state, equals(LifecycleState.loaded));
      });

      test('should return a useful future if it is already loading', () async {
        await gotoState(module, LifecycleState.loading);
        expect(module.isLoading, isTrue);
        var future = module.load();
        expect(module.isLoaded, isFalse);
        await future;
        expect(module.isLoaded, isTrue);
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
        expect(lastLogMessage, isNull);
        await module.load();
        expect(lastLogMessage, isNotNull);
        expect(lastLogMessage.level, equals(Level.WARNING));
      });

      test('should do nothing if it was already loaded', () async {
        await module.load();
        module.eventList.clear();
        await module.load();
        expect(module.eventList, equals([]));
      });

      test('should warn if it was already loaded', () async {
        await module.load();
        expect(lastLogMessage, isNull);
        await module.load();
        expect(lastLogMessage, isNotNull);
        expect(lastLogMessage.level, equals(Level.WARNING));
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
        'didUnload',
        'onDispose',
        'didDispose'
      ];

      test('should dispatch events and call onShouldUnload and onUnload',
          () async {
        await module.load();
        module.eventList.clear();
        await module.unload();
        expect(module.eventList, equals(expectedUnloadEvents));
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
        expect(module.state, equals(LifecycleState.loaded));
        var future = module.unload();
        expect(module.state, equals(LifecycleState.unloading));
        await future;
        expect(module.state, equals(LifecycleState.unloaded));
      });

      test('should dispose the module', () async {
        await module.load();
        expect(module.isDisposed, isFalse);
        await module.unload();
        expect(module.isDisposed, isTrue);
      });

      test('should alias dispose to unload', () async {
        await module.load();
        module.eventList.clear();
        // ignore: deprecated_member_use
        await module.dispose();
        expect(module.eventList, equals(expectedUnloadEvents));
        expect(module.isLoaded, isFalse);
        expect(module.isDisposed, isTrue);
      });

      test('should support unloading from suspended state', () async {
        await gotoState(module, LifecycleState.suspended);
        module.eventList.clear();
        expect(module.isSuspended, isTrue);
        expect(module.state, LifecycleState.suspended);

        await module.unload();

        expect(module.isUnloaded, isTrue);
        expect(module.state, LifecycleState.unloaded);
        expect(module.eventList, equals(expectedUnloadEvents));
      });

      test('should return a useful future if it is already unloading',
          () async {
        await gotoState(module, LifecycleState.unloading);
        expect(module.isUnloading, isTrue);
        var future = module.unload();
        expect(module.isUnloaded, isFalse);
        await future;
        expect(module.isUnloaded, isTrue);
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
        expect(lastLogMessage, isNull);
        await module.unload();
        expect(lastLogMessage, isNotNull);
        expect(lastLogMessage.level, equals(Level.WARNING));
      });

      test('should do nothing if it was already unloaded', () async {
        await gotoState(module, LifecycleState.unloaded);
        module.eventList.clear();
        await module.unload();
        expect(module.eventList, equals([]));
      });

      test('should warn if it was already unloaded', () async {
        await gotoState(module, LifecycleState.unloaded);
        expect(lastLogMessage, isNull);
        await module.unload();
        expect(lastLogMessage, isNotNull);
        expect(lastLogMessage.level, equals(Level.WARNING));
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
      });

      testInvalidTransitions(LifecycleState.unloading, [
        LifecycleState.initialized,
        LifecycleState.loading,
        LifecycleState.suspending,
        LifecycleState.resuming
      ]);
    });

    group('suspend', () {
      var expectedSuspendEvents = ['willSuspend', 'onSuspend', 'didSuspend'];

      test('should dispatch suspend events and call onSuspend', () async {
        await module.load();
        module.eventList.clear();
        await module.suspend();
        expect(module.eventList, equals(expectedSuspendEvents));
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
        expect(module.state, equals(LifecycleState.loaded));
        var future = module.suspend();
        expect(module.state, equals(LifecycleState.suspending));
        await future;
        expect(module.state, equals(LifecycleState.suspended));
      });

      test('should return a useful future if it is already suspending',
          () async {
        await gotoState(module, LifecycleState.suspending);
        expect(module.isSuspending, isTrue);
        var future = module.suspend();
        expect(module.isSuspended, isFalse);
        await future;
        expect(module.isSuspended, isTrue);
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
        expect(lastLogMessage, isNull);
        await module.suspend();
        expect(lastLogMessage, isNotNull);
        expect(lastLogMessage.level, equals(Level.WARNING));
      });

      test('should do nothing if it was already suspended', () async {
        await gotoState(module, LifecycleState.suspended);
        module.eventList.clear();
        await module.suspend();
        expect(module.eventList, equals([]));
      });

      test('should warn if it is already suspended', () async {
        await gotoState(module, LifecycleState.suspended);
        expect(lastLogMessage, isNull);
        await module.suspend();
        expect(lastLogMessage, isNotNull);
        expect(lastLogMessage.level, equals(Level.WARNING));
      });

      testInvalidTransitions(LifecycleState.suspending, [
        LifecycleState.initialized,
        LifecycleState.loading,
        LifecycleState.resuming,
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
        expect(module.state, equals(LifecycleState.suspended));
        var future = module.resume();
        expect(module.state, equals(LifecycleState.resuming));
        await future;
        expect(module.state, equals(LifecycleState.loaded));
      });

      test('should return a useful future if it is already resuming', () async {
        await gotoState(module, LifecycleState.resuming);
        expect(module.isResuming, isTrue);
        var future = module.resume();
        expect(module.isResuming, isTrue);
        await future;
        expect(module.isResuming, isFalse);
        expect(module.isLoaded, isTrue);
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
        expect(lastLogMessage, isNull);
        await module.resume();
        expect(lastLogMessage, isNotNull);
        expect(lastLogMessage.level, equals(Level.WARNING));
      });

      testInvalidTransitions(LifecycleState.resuming, [
        LifecycleState.initialized,
        LifecycleState.loading,
        LifecycleState.loaded,
        LifecycleState.suspending,
        LifecycleState.unloading,
        LifecycleState.unloaded
      ]);
    });
  });

  group('LifecycleModule with children', () {
    TestLifecycleModule parentModule;
    TestLifecycleModule childModule;

    setUp(() {
      parentModule = new TestLifecycleModule();
      childModule = new TestLifecycleModule();
    });

    test('loadChildModule loads a child module', () async {
      await parentModule.loadChildModule(childModule);
      expect(
          parentModule.eventList,
          equals([
            'onWillLoadChildModule',
            'willLoadChildModule',
            'onDidLoadChildModule',
            'didLoadChildModule'
          ]));
      expect(childModule.eventList, equals(['willLoad', 'onLoad', 'didLoad']));
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
    });

    test('should suspend child modules when parent is suspended', () async {
      await parentModule.load();
      await parentModule.loadChildModule(childModule);
      parentModule.eventList.clear();
      childModule.eventList.clear();
      await parentModule.suspend();
      expect(parentModule.eventList,
          equals(['willSuspend', 'onSuspend', 'didSuspend']));
      expect(childModule.eventList,
          equals(['willSuspend', 'onSuspend', 'didSuspend']));
    });

    test('should resume child modules when parent is resumed', () async {
      await parentModule.load();
      await parentModule.loadChildModule(childModule);
      await parentModule.suspend();
      parentModule.eventList.clear();
      childModule.eventList.clear();
      await parentModule.resume();
      expect(parentModule.eventList,
          equals(['willResume', 'onResume', 'didResume']));
      expect(childModule.eventList,
          equals(['willResume', 'onResume', 'didResume']));
    });

    test('should unload child modules when parent is unloaded', () async {
      await parentModule.load();
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
            'didUnload',
            'onDispose',
            'didDispose'
          ]));
      expect(
          childModule.eventList,
          equals([
            'onShouldUnload',
            'onShouldUnload',
            'willUnload',
            'onUnload',
            'didUnload',
            'onDispose',
            'didDispose'
          ]));
    });

    test(
        'unloaded child module should be removed from lifecycle of parent module',
        () async {
      await parentModule.load();
      await parentModule.loadChildModule(childModule);
      parentModule.eventList.clear();
      childModule.eventList.clear();

      await childModule.unload();
      expect(
          childModule.eventList,
          equals([
            'onShouldUnload',
            'willUnload',
            'onUnload',
            'didUnload',
            'onDispose',
            'didDispose'
          ]));
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
      expect(
          parentModule.eventList,
          equals([
            'onShouldUnload',
            'willUnload',
            'onUnload',
            'didUnload',
            'onDispose',
            'didDispose'
          ]));
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
  });

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
