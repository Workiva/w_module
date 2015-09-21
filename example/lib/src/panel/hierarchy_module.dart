library w_module.example.panel.hierarchy_module;

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

class HierarchyModule extends Module {
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
      loadChildModule(module);
    });
  }
}

class HierarchyComponents implements ModuleComponents {
  HierarchyActions _actions;
  HierarchyStore _stores;

  HierarchyComponents(this._actions, this._stores);

  content() => HierarchyComponent({'actions': _actions, 'store': _stores});
}

class HierarchyActions {
  final Action<Module> addChildModule = new Action<Module>();
  final Action<Module> removeChildModule = new Action<Module>();
}

class HierarchyStore extends Store {
  /// Public data
  List<Module> _childModules = [];
  List<Module> get childModules => _childModules;

  /// Internals
  HierarchyActions _actions;

  HierarchyStore(HierarchyActions this._actions) {
    triggerOnAction(_actions.addChildModule, _addChildModule);
    triggerOnAction(_actions.removeChildModule, _removeChildModule);
  }

  _addChildModule(Module newModule) {
    _childModules.add(newModule);
  }

  _removeChildModule(Module oldModule) {
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

var HierarchyComponent =
    react.registerComponent(() => new _HierarchyComponent());

class _HierarchyComponent
    extends FluxComponent<HierarchyActions, HierarchyStore> {
  render() {
    return react.div(
        {
      'style': {
        'padding': '10px',
        'backgroundColor': 'lightgray',
        'color': 'black'
      }
    },
        store.childModules.map((child) => react.div({
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
}
