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

library w_module.example.panel.modules.flux_module;

import 'dart:math';

import 'package:w_flux/w_flux.dart';
import 'package:react/react.dart' as react;
import 'package:w_module/w_module.dart';

class FluxModule extends Module {
  @override
  final String name = 'FluxModule';

  FluxActions _actions;
  FluxComponents _components;
  FluxStore _stores;

  FluxModule() {
    _actions = new FluxActions();
    _stores = new FluxStore(_actions);
    _components = new FluxComponents(_actions, _stores);
  }

  @override
  FluxComponents get components => _components;
}

class FluxComponents implements ModuleComponents {
  FluxActions _actions;
  FluxStore _stores;

  FluxComponents(this._actions, this._stores);

  @override
  Object content() => MyFluxComponent({'actions': _actions, 'store': _stores});
}

class FluxActions {
  final Action changeBackgroundColor = new Action();
}

class FluxStore extends Store {
  FluxActions _actions;
  String _backgroundColor = 'gray';

  FluxStore(this._actions) {
    triggerOnAction(_actions.changeBackgroundColor, _changeBackgroundColor);
  }

  String get backgroundColor => _backgroundColor;

  void _changeBackgroundColor(_) {
    // generate a random hex color string
    _backgroundColor =
        '#' + (new Random().nextDouble() * 16777215).floor().toRadixString(16);
  }
}

// ignore: non_constant_identifier_names
var MyFluxComponent = react.registerComponent(() => new _MyFluxComponent());

class _MyFluxComponent extends FluxComponent<FluxActions, FluxStore> {
  @override
  Object render() {
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
      }, 'Random Background Color')
    ]);
  }
}
