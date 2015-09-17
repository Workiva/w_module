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

library w_module.example.random_color;

import 'dart:html';
import 'dart:math';

import 'package:react/react.dart' as react;
import 'package:react/react_client.dart' as react_client;

import 'package:w_flux/w_flux.dart';
import 'package:w_module/w_module.dart';

main() async {
  // instantiate the module and wait for it to load
  RandomColorModule randomColorModule = new RandomColorModule();
  await randomColorModule.load();

  // render the module's UI component
  react_client.setClientConfiguration();
  react.render(randomColorModule.components.content(),
      querySelector('#content-container'));
}

class RandomColorModule extends Module {
  final String name = 'RandomColorModule';

  RandomColorActions _actions;
  RandomColorStore _stores;

  RandomColorComponents _components;
  RandomColorComponents get components => _components;

  RandomColorModule() {
    _actions = new RandomColorActions();
    _stores = new RandomColorStore(_actions);
    _components = new RandomColorComponents(_actions, _stores);
  }
}

class RandomColorComponents implements ModuleComponents {
  RandomColorActions _actions;
  RandomColorStore _stores;

  RandomColorComponents(this._actions, this._stores);

  content() => RandomColorComponent({'actions': _actions, 'store': _stores});
}

class RandomColorActions {
  final Action changeBackgroundColor = new Action();
}

class RandomColorStore extends Store {
  /// Public data
  String _backgroundColor = 'gray';
  String get backgroundColor => _backgroundColor;

  /// Internals
  RandomColorActions _actions;

  RandomColorStore(RandomColorActions this._actions) {
    _actions.changeBackgroundColor.listen(_changeBackgroundColor);
  }

  _changeBackgroundColor(_) {
    // generate a random hex color string
    _backgroundColor =
        '#' + (new Random().nextDouble() * 16777215).floor().toRadixString(16);
    trigger();
  }
}

var RandomColorComponent =
    react.registerComponent(() => new _RandomColorComponent());

class _RandomColorComponent
    extends FluxComponent<RandomColorActions, RandomColorStore> {
  render() {
    return react.div({
      'style': {
        'padding': '50px',
        'backgroundColor': store.backgroundColor,
        'color': 'white'
      }
    }, [
      'This module uses a flux pattern to change its background color.',
      react.button({
        'style': {'padding': '10px', 'margin': '10px'},
        'onClick': actions.changeBackgroundColor
      }, 'Change Background Color')
    ]);
  }
}
