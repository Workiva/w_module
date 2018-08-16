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

library w_module.example.panel.modules.lifecycle_echo_module;

import 'dart:async';

import 'package:meta/meta.dart' show protected;
import 'package:react/react.dart' as react;
import 'package:w_module/w_module.dart';

class LifecycleEchoModule extends Module {
  LifecycleEchoComponents _components;

  LifecycleEchoModule() {
    // load / unload state streams
    willLoad.listen((_) {
      print('$name: willLoad');
    });
    didLoad.listen((_) {
      print('$name: didLoad');
    });
    willUnload.listen((_) {
      print('$name: willUnload');
    });
    didUnload.listen((_) {
      print('$name: didUnload');
    });
    didLoadChildModule.listen((_) {
      print('$name: didLoadChildModule');
    });
    _components = new LifecycleEchoComponents();
  }

  @override
  LifecycleEchoComponents get components => _components;

  //--------------------------------------------------------
  // Methods that can be optionally implemented by subclasses
  // to execute code during certain phases of the module
  // lifecycle
  //--------------------------------------------------------

  @override
  @protected
  Future<Null> onLoad() async {
    print('$name: onLoad');
    await loadChildModule(new LifecycleEchoChildModule());
    await new Future.delayed(new Duration(seconds: 1));
  }

  @override
  @protected
  ShouldUnloadResult onShouldUnload() {
    print('$name: onShouldUnload');
    return new ShouldUnloadResult();
  }

  @override
  @protected
  Future<Null> onUnload() async {
    print('$name: onUnload');
    await new Future.delayed(new Duration(seconds: 1));
  }
}

class LifecycleEchoComponents implements ModuleComponents {
  @override
  Object content() => react.div({
        'style': {
          'padding': '50px',
          'backgroundColor': 'lightGray',
          'color': 'black'
        }
      }, [
        'This module echoes all of its lifecycle events to the dev console.'
      ]);
}

class LifecycleEchoChildModule extends Module {
  @override
  String get name => 'LifecycleEchoChildModule';
}
