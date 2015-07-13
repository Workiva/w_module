library w_module.example.panel.flux_module;

import 'dart:math';

import 'package:w_flux/w_flux.dart';
import 'package:react/react.dart' as react;
import 'package:web_skin_react/web_skin_react.dart' as WSR;

import './panel_content.dart';

class FluxModule extends PanelContent {
  final String name = 'FluxModule';

  FluxActions _actions;
  FluxStore _stores;

  FluxComponents _components;
  FluxComponents get components => _components;

  FluxModule() {
    _actions = new FluxActions();
    _stores = new FluxStore(_actions);
    _components = new FluxComponents(_actions, _stores);
  }
}

class FluxComponents implements PanelContentComponents {
  FluxActions _actions;
  FluxStore _stores;

  FluxComponents(this._actions, this._stores);

  content() => MyFluxComponent({'actions': _actions, 'stores': _stores});
}

class FluxActions {
  final Action changeBackgroundColor = new Action();
}

class FluxStore extends Store {

  /// Public data
  String _backgroundColor = 'gray';
  String get backgroundColor => _backgroundColor;

  /// Internals
  FluxActions _actions;

  FluxStore(FluxActions this._actions) {
    triggerOnAction(_actions.changeBackgroundColor, _changeBackgroundColor);
  }

  _changeBackgroundColor(_) {
    // generate a random hex color string
    _backgroundColor = '#' + (new Random().nextDouble() * 16777215).floor().toRadixString(16);
  }
}

var MyFluxComponent = react.registerComponent(() => new _MyFluxComponent());
class _MyFluxComponent extends FluxComponent<FluxActions, FluxStore> {
  String get backgroundColor => state['backgroundColor'];

  getStoreHandlers() => {stores: _updateFluxStore};

  getInitialState() {
    return {'backgroundColor': stores.backgroundColor};
  }

  render() {
    return react.div({
      'style': {'padding': '50px', 'backgroundColor': backgroundColor, 'color': 'white'}
    }, [
      'This module uses a flux pattern to change its background color.',
      WSR.Input({
        'type': 'submit',
        'value': 'Random Background Color',
        'onClick': actions.changeBackgroundColor
      })
    ]);
  }

  _updateFluxStore(FluxStore store) {
    setState({'backgroundColor': store.backgroundColor});
  }
}
