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
library w_module.test.lifecycle_module_test;

import 'dart:async';

import 'package:w_module/w_module.dart';
import 'package:test/test.dart';

const String shouldUnloadError = 'Mock shouldUnload false message';

class TestLifecycleModule extends LifecycleModule {
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

  Future onWillLoadChildModule(LifecycleModule module) async {
    eventList.add('onWillLoadChildModule');
  }

  Future onDidLoadChildModule(LifecycleModule module) async {
    eventList.add('onDidLoadChildModule');
  }

  Future onWillUnloadChildModule(LifecycleModule module) async {
    eventList.add('onWillUnloadChildModule');
  }

  Future onDidUnloadChildModule(LifecycleModule module) async {
    eventList.add('onDidUnloadChildModule');
  }

  Future onLoad() async {
    await new Future.delayed(new Duration(milliseconds: 1));
    eventList.add('onLoad');
  }

  ShouldUnloadResult onShouldUnload() {
    eventList.add('onShouldUnload');
    if (mockShouldUnload) {
      return new ShouldUnloadResult();
    } else {
      return new ShouldUnloadResult(false, shouldUnloadError);
    }
  }

  Future onUnload() async {
    await new Future.delayed(new Duration(milliseconds: 1));
    eventList.add('onUnload');
  }
}

void main() {
  group('LifecycleModule', () {
    TestLifecycleModule module;

    setUp(() {
      module = new TestLifecycleModule();
    });

    test('should trigger loading events and call onLoad when module is loaded',
        () async {
      await module.load();
      expect(module.eventList, equals(['willLoad', 'onLoad', 'didLoad']));
    });

    test(
        'should trigger unloading events and call onShouldUnload and onUnload when module is unloaded',
        () async {
      await module.unload();
      expect(module.eventList,
          equals(['onShouldUnload', 'willUnload', 'onUnload', 'didUnload']));
    });

    test(
        'should throw an exception if attempting to unload module and shouldUnload completes false',
        () async {
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

    test('should unload child modules when parent in unloaded', () async {
      await parentModule.loadChildModule(childModule);
      parentModule.eventList = [];
      childModule.eventList = [];
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

    test(
        'unloaded child module should be removed from lifecycle of parent module',
        () async {
      await parentModule.loadChildModule(childModule);
      parentModule.eventList = [];
      childModule.eventList = [];

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
      parentModule.eventList = [];
      childModule.eventList = [];

      // Verify that subscriptions have been canceled.
      await childModule.load();
      await childModule.unload();
      await new Future(() {});
      expect(parentModule.eventList, equals([]));
      childModule.eventList = [];

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
      parentModule.eventList = [];
      childModule.eventList = [];

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
      parentModule.eventList = [];
      childModule.eventList = [];

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
