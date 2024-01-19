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

library w_module.example.random_color;

import 'dart:async';
import 'dart:html' as html;
import 'dart:math';

import 'package:react/react.dart' as react;
import 'package:over_react/over_react.dart';
import 'package:react/react_dom.dart' as react_dom;
import 'package:react/react_client.dart' as react_client;

import 'package:w_flux/w_flux.dart';
import 'package:w_module/w_module.dart';

Future<Null> main() async {
  // instantiate the module and wait for it to load
  RandomColorModule randomColorModule = RandomColorModule();
  await randomColorModule.load();

  // render the module's UI component
  react_client.setClientConfiguration();
  react_dom.render(ErrorBoundary()(randomColorModule.components.content()),
      html.querySelector('#content-container'));

  // exercise the module's API via some simple button clicks
  html
      .querySelector('#random-color')
      .onClick
      .listen((_) => randomColorModule.api.changeBackgroundColor());
  html
      .querySelector('#purple-color')
      .onClick
      .listen((_) => randomColorModule.api.setBackgroundColor('purple'));

  // use public API to display the initial background color
  html.querySelector('#current-color').innerHtml =
      randomColorModule.api.currentBackgroundColor;

  // process public events dispatched from the module
  randomColorModule.events.colorChanged.listen((newColor) {
    html.Element colorSpan = html.querySelector('#current-color');
    colorSpan.innerHtml = newColor;
    colorSpan.style.color = newColor;
  });
}

DispatchKey randomColorModuleDispatchKey = DispatchKey('randomColor');

class RandomColorModule extends Module {
  @override
  final String name = 'RandomColorModule';

  RandomColorActions _actions;
  RandomColorApi _api;
  RandomColorComponents _components;
  RandomColorEvents _events;
  RandomColorStore _stores;

  RandomColorModule() {
    _actions = RandomColorActions();
    _events = RandomColorEvents();
    _stores = RandomColorStore(_actions, _events, randomColorModuleDispatchKey);
    _components = RandomColorComponents(_actions, _stores);
    _api = RandomColorApi(_actions, _stores);
  }

  @override
  RandomColorApi get api => _api;

  @override
  RandomColorComponents get components => _components;

  @override
  RandomColorEvents get events => _events;
}

class RandomColorApi {
  RandomColorActions _actions;
  RandomColorStore _stores;

  RandomColorApi(this._actions, this._stores);

  void setBackgroundColor(String newColor) {
    _actions.setBackgroundColor(newColor);
  }

  void changeBackgroundColor() {
    _actions.changeBackgroundColor(null);
  }

  String get currentBackgroundColor => _stores.backgroundColor;
}

class RandomColorEvents {
  final Event<String> colorChanged = Event(randomColorModuleDispatchKey);
}

class RandomColorComponents implements ModuleComponents {
  RandomColorActions _actions;
  RandomColorStore _stores;

  RandomColorComponents(this._actions, this._stores);

  @override
  Object content() =>
      RandomColorComponent({'actions': _actions, 'store': _stores});
}

class RandomColorActions {
  final ActionV2<Null> changeBackgroundColor = ActionV2();
  final ActionV2<String> setBackgroundColor = ActionV2();
}

class RandomColorStore extends Store {
  /// Public data
  String _backgroundColor = 'gray';

  RandomColorEvents _events;
  DispatchKey _dispatchKey;

  /// Internals
  RandomColorActions _actions;

  RandomColorStore(this._actions, this._events, this._dispatchKey) {
    _actions.changeBackgroundColor.listen(_changeBackgroundColor);
    _actions.setBackgroundColor.listen(_setBackgroundColor);
  }

  String get backgroundColor => _backgroundColor;

  void _changeBackgroundColor(_) {
    // generate a random hex color string
    _backgroundColor =
        '#' + (Random().nextDouble() * 16777215).floor().toRadixString(16);
    _events.colorChanged(_backgroundColor, _dispatchKey);
    trigger();
  }

  void _setBackgroundColor(String newColor) {
    // generate a random hex color string
    _backgroundColor = newColor;
    _events.colorChanged(_backgroundColor, _dispatchKey);
    trigger();
  }
}

// ignore: non_constant_identifier_names
var RandomColorComponent =
    react.registerComponent(() => _RandomColorComponent());

class _RandomColorComponent
    extends FluxComponent<RandomColorActions, RandomColorStore> {
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
        'onClick': (_) => actions.changeBackgroundColor(null)
      }, 'Change Background Color'),
      react.button({
        'style': {'padding': '10px', 'margin': '10px'},
        'onClick': (_) => actions.setBackgroundColor('red')
      }, 'Make Background Red')
    ]);
  }
}
