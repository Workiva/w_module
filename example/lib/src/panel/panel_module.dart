library w_module.example.panel.panel_module;

import 'dart:async';
import 'dart:html';

import 'package:w_module/w_module.dart';
import 'package:w_flux/w_flux.dart';
import 'package:react/react.dart' as react;
import 'package:web_skin_react/web_skin_react.dart' as WSR;

import './basic_module.dart';
import './flux_module.dart';
import './reject_module.dart';
import './dataLoadAsync_module.dart';
import './dataLoadBlocking_module.dart';
import './deferred_module.dart';
import './lifecycleEcho_module.dart';
import './hierarchy_module.dart';

class PanelModule extends Module {
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

  Future onLoad() async {
    _actions.changeToPanel(0);
  }
}

class PanelComponents implements ModuleComponents {
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
  bool _isRenderable = false;
  bool get isRenderable => _isRenderable;
  Module _panelModule;
  Module get panelModule => _panelModule;

  /// Internals
  PanelActions _actions;
  LifecycleModule _parentModule;

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
      _isRenderable = false;
      _panelModule.unload();
    }

    // extra trigger to show loading indicator
    _panelIndex = newPanelIndex;
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
    _isRenderable = true;
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
    var tabBar = WSR.Nav({
      'wsStyle': 'pills',
      'justified': true,
      'activeKey': panelIndex,
      'onSelect': (newIndex, _, __) => actions.changeToPanel(newIndex),
      'style': {'paddingBottom': '5px'}
    }, [
      WSR.NavItem({'eventKey': 0}, 'Basic'),
      WSR.NavItem({'eventKey': 1}, 'Flux'),
      WSR.NavItem({'eventKey': 2}, 'Reject'),
      WSR.NavItem({'eventKey': 3}, 'Data Load (async)'),
      WSR.NavItem({'eventKey': 4}, 'Data Load (blocking)'),
      WSR.NavItem({'eventKey': 5}, 'Deferred'),
      WSR.NavItem({'eventKey': 6}, 'Lifecycle Echo'),
      WSR.NavItem({'eventKey': 7}, 'All of them'),
      WSR.NavItem({'eventKey': 8}, 'Recursive')
    ]);

    return react.div({
      'style': {
        'padding': '5px',
        'backgroundColor': 'white',
        'color': 'black',
        'border': '1px solid lightgreen'
      }
    }, [tabBar, panelContent]);
  }

  _updatePanelStore(PanelStore store) {
    // display a loading placeholder if the module isn't ready for rendering
    var content = store.isRenderable
        ? store.panelModule.components.content()
        : WSR.ProgressBar(
            {'wsStyle': 'success', 'indeterminate': true, 'label': 'Loading New Panel Module...'});
    setState({'panelIndex': store.panelIndex, 'panelContent': content});
  }
}
