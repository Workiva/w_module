library w_module.example.panel.panel_module;

import 'dart:html';

import 'package:w_module/w_module.dart';
import 'package:w_flux/w_flux.dart';
import 'package:react/react.dart' as react;
import 'package:web_skin_react/web_skin_react.dart' as WSR;

import './panel_content.dart';
import './basic_module.dart';
import './flux_module.dart';
import './reject_module.dart';
import './dataLoadAsync_module.dart';
import './dataLoadBlocking_module.dart';
import './deferred_module.dart';
import './lifecycleEcho_module.dart';
import './hierarchy_module.dart';

class PanelModule extends PanelContent {
  final String name = 'PanelModule';

  PanelActions _actions;
  PanelStore _stores;

  PanelComponents _components;
  PanelComponents get components => _components;

  PanelModule() {
    _actions = new PanelActions();
    _stores = new PanelStore(_actions, this);
    _components = new PanelComponents(_actions, _stores);
  }

  onLoad() {
    _actions.changeToPanel(0);
  }
}

class PanelComponents implements PanelContentComponents {
  PanelActions _actions;
  PanelStore _stores;

  PanelComponents(this._actions, this._stores);

  content() => PanelComponent({'actions': _actions, 'stores': _stores});
}

class PanelActions {
  final Action<num> changeToPanel = new Action<num>();
}

class PanelStore extends Store {

  /// Public data
  num _panelIndex = 0;
  num get panelIndex => _panelIndex;

  /// Internals
  PanelActions _actions;
  LifecycleModule _parentModule;
  PanelContent _panelModule;

  // TODO - don't manage panelContent in the store this way
  var panelContent = null;

  PanelStore(PanelActions this._actions, LifecycleModule this._parentModule) {
    triggerOnAction(_actions.changeToPanel, _changeToPanel);
  }

  _changeToPanel(num newPanelIndex) async {

    // is there a panel currently loaded?
    if (_panelModule != null) {

      // do we need to reject the unload of the existing panel?
      ShouldUnloadResult canUnload = _panelModule.shouldUnload();
      if (!canUnload.shouldUnload) {
        // reject the change with an alert and short circuit
        window.alert(canUnload.messagesAsString());
        return;
      }

      // unload the existing panel
      _panelModule.unload();
    }

    // show a loading indicator while loading the module
    _panelIndex = newPanelIndex;
    panelContent = WSR.ProgressBar(
        {'wsStyle': 'success', 'indeterminate': true, 'label': 'Loading New Panel Module...'});
    trigger();

    // load the new panel
    if (_panelIndex == 0) {
      _panelModule = new BasicModule();
    } else if (_panelIndex == 1) {
      _panelModule = new FluxModule();
    } else if (_panelIndex == 2) {
      _panelModule = new RejectModule();
    } else if (_panelIndex == 3) {
      _panelModule = new DataLoadAsyncModule();
    } else if (_panelIndex == 4) {
      _panelModule = new DataLoadBlockingModule();
    } else if (_panelIndex == 5) {
      _panelModule = new DeferredModule();
    } else if (_panelIndex == 6) {
      _panelModule = new LifecycleEchoModule();
    } else if (_panelIndex == 7) {
      _panelModule = new HierarchyModule();
    } else if (_panelIndex == 8) {
      _panelModule = new PanelModule();
    }
    await _parentModule.loadModule(_panelModule);

    if (_panelIndex == 8) {
      // add some border for the recursive case
      panelContent = react.div({
        'style': {'padding': '5px', 'backgroundColor': 'white', 'color': 'black'}
      }, _panelModule.components.content());
    } else {
      panelContent = _panelModule.components.content();
    }
  }
}

var PanelComponent = react.registerComponent(() => new _PanelComponent());
class _PanelComponent extends FluxComponent<PanelActions, PanelStore> {
  num get panelIndex => state['panelIndex'];
  get panelContent => state['panelContent'];

  getStoreHandlers() => {stores: _updatePanelStore};

  getInitialState() {
    return {'panelIndex': 0, 'panelContent': null};
  }

  render() {
    var toolbar = WSR.ButtonGroup({}, [
      WSR.Button({
        'wsStyle': 'light',
        'active': panelIndex == 0,
        'onClick': (_) => actions.changeToPanel(0)
      }, 'Basic'),
      WSR.Button({
        'wsStyle': 'inverse',
        'active': panelIndex == 1,
        'onClick': (_) => actions.changeToPanel(1)
      }, 'Flux'),
      WSR.Button({
        'wsStyle': 'success',
        'active': panelIndex == 2,
        'onClick': (_) => actions.changeToPanel(2)
      }, 'Reject'),
      WSR.Button({
        'wsStyle': 'warning',
        'active': panelIndex == 3,
        'onClick': (_) => actions.changeToPanel(3)
      }, 'Data Load (async)'),
      WSR.Button({
        'wsStyle': 'danger',
        'active': panelIndex == 4,
        'onClick': (_) => actions.changeToPanel(4)
      }, 'Data Load (blocking)'),
      WSR.Button({
        'wsStyle': 'info',
        'active': panelIndex == 5,
        'onClick': (_) => actions.changeToPanel(5)
      }, 'Deferred'),
      WSR.Button({
        'active': panelIndex == 6,
        'onClick': (_) => actions.changeToPanel(6)
      }, 'Lifecycle Echo'),
      WSR.Button(
          {'active': panelIndex == 7, 'onClick': (_) => actions.changeToPanel(7)}, 'All of them'),
      WSR.Button({'active': panelIndex == 8, 'onClick': (_) => actions.changeToPanel(8)}, 'Recurse')
    ]);

    return react.div({}, [toolbar, panelContent]);
  }

  _updatePanelStore(PanelStore store) {
    setState({'panelIndex': store.panelIndex, 'panelContent': store.panelContent});
  }
}
