library w_module.example.panel.hierarchy_module;

import 'dart:async';
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

class HierarchyModule extends PanelContent {
  final String name = 'HierarchyModule';

  HierarchyActions _actions;
  HierarchyStore _stores;

  HierarchyComponents _components;
  HierarchyComponents get components => _components;

  HierarchyModule() {
    _actions = new HierarchyActions();
    _stores = new HierarchyStore(_actions);
    _components = new HierarchyComponents(_actions, _stores);
  }

  Future onLoad() async {

    // can optionally await all of the loadModule calls
    // to force all children to load before this module
    // completes loading (not recommended)

    List<LifecycleModule> allOfThem = [
      new BasicModule(),
      new FluxModule(),
      new RejectModule(),
      new DataLoadAsyncModule(),
      new DataLoadBlockingModule(),
      new DeferredModule(),
      new LifecycleEchoModule()
    ];

    allOfThem.forEach((module) {
      module.didLoad.listen((_) {
        _actions.addChildModule(module);
      });
      loadModule(module);
    });
  }
}

class HierarchyComponents implements PanelContentComponents {
  HierarchyActions _actions;
  HierarchyStore _stores;

  HierarchyComponents(this._actions, this._stores);

  content() => HierarchyComponent({'actions': _actions, 'stores': _stores});
}

class HierarchyActions {
  final Action<PanelContent> addChildModule = new Action<PanelContent>();
  final Action<PanelContent> removeChildModule = new Action<PanelContent>();
}

class HierarchyStore extends Store {

  /// Public data
  List<PanelContent> _childModules = [];
  List<PanelContent> get childModules => _childModules;

  /// Internals
  HierarchyActions _actions;

  HierarchyStore(HierarchyActions this._actions) {
    triggerOnAction(_actions.addChildModule, _addChildModule);
    triggerOnAction(_actions.removeChildModule, _removeChildModule);
  }

  _addChildModule(PanelContent newModule) {
    _childModules.add(newModule);
  }

  _removeChildModule(PanelContent oldModule) {

    // do we need to reject the unload?
    ShouldUnloadResult canUnload = oldModule.shouldUnload();
    if (!canUnload.shouldUnload) {
      // reject the change with an alert and short circuit
      window.alert(canUnload.messagesAsString());
      return;
    }

    // continue with unload
    _childModules.remove(oldModule);
    oldModule.unload();
  }
}

var HierarchyComponent = react.registerComponent(() => new _HierarchyComponent());
class _HierarchyComponent extends FluxComponent<HierarchyActions, HierarchyStore> {
  List<PanelContent> get childModules => state['childModules'];

  getStoreHandlers() => {stores: _updateHierarchyStore};

  getInitialState() {
    return {'childModules': []};
  }

  render() {
    return react.div({
      'style': {'padding': '10px', 'backgroundColor': 'lightgray', 'color': 'black'}
    }, childModules.map((child) => react.div({
      'style': {'border': '3px dashed gray', 'margin': '5px'}
    }, [
      WSR.Button({
        'style': {'float': 'right', 'margin': '5px'},
        'onClick': (_) {
          actions.removeChildModule(child);
        }
      }, 'Unload Module'),
      child.components.content()
    ])));
  }

  _updateHierarchyStore(HierarchyStore store) {
    setState({'childModules': store.childModules});
  }
}
