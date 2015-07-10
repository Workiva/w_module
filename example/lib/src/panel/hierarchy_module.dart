library w_module.example.panel.hierarchy_module;

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


class HierarchyModule extends ViewModule {

  final String name = 'HierarchyModule';

  get api => null;
  get events => null;

  buildComponent() => HierarchyComponent({
    'actions': _actions,
    'stores': _stores
  });

  HierarchyActions _actions;
  HierarchyStore _stores;

  HierarchyModule() {
    _actions = new HierarchyActions();
    _stores = new HierarchyStore(_actions);
  }

  onLoad() {

    // can optionally await all of the loadModule calls
    // to force all children to load before this module
    // completes loading (not recommended)

    BasicModule basicMod = new BasicModule();
    basicMod.didLoad = () { _actions.addChildModule(basicMod); };
    loadModule(basicMod);

    FluxModule fluxMod = new FluxModule();
    fluxMod.didLoad = () { _actions.addChildModule(fluxMod); };
    loadModule(fluxMod);

    RejectModule rejectMod = new RejectModule();
    rejectMod.didLoad = () { _actions.addChildModule(rejectMod); };
    loadModule(rejectMod);

    DataLoadAsyncModule dataLoadAsyncMod = new DataLoadAsyncModule();
    dataLoadAsyncMod.didLoad = () { _actions.addChildModule(dataLoadAsyncMod); };
    loadModule(dataLoadAsyncMod);

    DataLoadBlockingModule dataLoadBlockingMod = new DataLoadBlockingModule();
    dataLoadBlockingMod.didLoad = () { _actions.addChildModule(dataLoadBlockingMod); };
    loadModule(dataLoadBlockingMod);

    DeferredModule deferredMod = new DeferredModule();
    deferredMod.didLoad = () { _actions.addChildModule(deferredMod); };
    loadModule(deferredMod);

    LifecycleEchoModule lifecycleEchoMod = new LifecycleEchoModule();
    lifecycleEchoMod.didLoad = () { _actions.addChildModule(lifecycleEchoMod); };
    loadModule(lifecycleEchoMod);

  }

}


class HierarchyActions {
  final Action<ViewModule> addChildModule = new Action<ViewModule>();
  final Action<ViewModule> removeChildModule = new Action<ViewModule>();
}


class HierarchyStore extends Store {

  /// Public data
  List<ViewModule> _childModules = [];
  List<ViewModule> get childModules => _childModules;

  /// Internals
  HierarchyActions _actions;

  HierarchyStore(HierarchyActions this._actions) {
    triggerOnAction(_actions.addChildModule, _addChildModule);
    triggerOnAction(_actions.removeChildModule, _removeChildModule);
  }

  _addChildModule(ViewModule newViewModule) {
    _childModules.add(newViewModule);
  }

  _removeChildModule(ViewModule oldViewModule) {

    // do we need to reject the unload?
    ShouldUnloadResult canUnload = oldViewModule.shouldUnload();
    if (!canUnload.shouldUnload) {
      // reject the change with an alert and short circuit
      window.alert(canUnload.messagesAsString());
      return;
    }

    // continue with unload
    _childModules.remove(oldViewModule);
    oldViewModule.unload();
  }
}


var HierarchyComponent = react.registerComponent(() => new _HierarchyComponent());
class _HierarchyComponent extends FluxComponent<HierarchyActions, HierarchyStore> {

  List<ViewModule> get childModules => state['childModules'];

  getStoreHandlers() => {
    stores: _updateHierarchyStore
  };

  getInitialState() {
    return {
      'childModules': []
    };
  }

  render() {

    return react.div({
        'style': {
          'padding': '20px',
          'backgroundColor': 'gray',
          'color': 'black'
        }
      },
      childModules.map((child) => react.div({}, [
          WSR.Button({
            'style': {
              'float': 'right'
            },
            'onClick': (_) { actions.removeChildModule(child); }
          }, 'Unload Module'),
          child.buildComponent()
        ])
      )
    );

  }

  _updateHierarchyStore(HierarchyStore store) {
    setState({
      'childModules': store.childModules
    });
  }
}

