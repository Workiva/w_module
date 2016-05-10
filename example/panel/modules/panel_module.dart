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

library w_module.example.panel.modules.panel_module;

import 'dart:async';
import 'dart:html';

import 'package:w_module/w_module.dart';
import 'package:w_flux/w_flux.dart';
import 'package:w_router/w_router.dart';
import 'package:react/react.dart' as react;

import './basic_module.dart';
import './flux_module.dart';
import './reject_module.dart';
import './dataLoadAsync_module.dart';
import './dataLoadBlocking_module.dart';
import './deferred_module.dart';
import './lifecycleEcho_module.dart';
import './hierarchy_module.dart';

num panelCounter = 1;

class PanelModule extends RouterModule {
  final String name = 'PanelModule';

  PanelActions _actions;
  PanelStore _stores;

  PanelComponents _components;
  PanelComponents get components => _components;

  num panelInst;

  PanelModule childPanel;
  bool factoryRun = false;

  PanelModule() {
    panelInst = panelCounter++;
    initRouter();
    _actions = new PanelActions();
    _stores = new PanelStore(router, _actions, this);
    _components = new PanelComponents(_actions, _stores, router);
  }

  Future onLoad() async {
    // TODO - may not be necessary
//    router.gotoUrl('/');
  }

  Future onUnload() async {
    // detach and clean up the router
  }

  void configureRoute(Route route) {
    // TODO - why does new entrance to deep route not instantiate modules and render the nest?
    route
      ..addRoute(
          name: 'basic_module',
          path: '/basic',
          pageTitle: 'Panel Example: Basic Module',
          defaultRoute: true,
          enter: (_) => _actions.changeToPanel(0),
          preLeave: (RoutePreLeaveEvent e) =>
              e.allowLeave(new Future.value(_stores.panelCanChange)))
      ..addRoute(
          name: 'flux_module',
          path: '/flux',
          pageTitle: 'Panel Example: Flux Module',
          enter: (_) => _actions.changeToPanel(1),
          preLeave: (RoutePreLeaveEvent e) =>
              e.allowLeave(new Future.value(_stores.panelCanChange)))
      ..addRoute(
          name: 'reject_module',
          path: '/reject',
          pageTitle: 'Panel Example: Reject Module',
          enter: (_) => _actions.changeToPanel(2),
          preLeave: (RoutePreLeaveEvent e) =>
              e.allowLeave(new Future.value(_stores.panelCanChange)))
      ..addRoute(
          name: 'dataLoad_async_module',
          path: '/dataLoad_async',
          pageTitle: 'Panel Example: Data Load (async) Module',
          enter: (_) => _actions.changeToPanel(3),
          preLeave: (RoutePreLeaveEvent e) =>
              e.allowLeave(new Future.value(_stores.panelCanChange)))
      ..addRoute(
          name: 'dataLoad_blocking_module',
          path: '/dataLoad_blocking',
          pageTitle: 'Panel Example: Data Load (blocking) Module',
          enter: (_) => _actions.changeToPanel(4),
          preLeave: (RoutePreLeaveEvent e) =>
              e.allowLeave(new Future.value(_stores.panelCanChange)))
      ..addRoute(
          name: 'deferred_module',
          path: '/deferred',
          pageTitle: 'Panel Example: Deferred Module',
          enter: (_) => _actions.changeToPanel(5),
          preLeave: (RoutePreLeaveEvent e) =>
              e.allowLeave(new Future.value(_stores.panelCanChange)))
      ..addRoute(
          name: 'lifecycle_echo_module',
          path: '/lifecycle_echo',
          pageTitle: 'Panel Example: Lifecycle Echo Module',
          enter: (_) => _actions.changeToPanel(6),
          preLeave: (RoutePreLeaveEvent e) =>
              e.allowLeave(new Future.value(_stores.panelCanChange)))
      ..addRoute(
          name: 'hierarchy_module',
          path: '/hierarchy',
          pageTitle: 'Panel Example: Hierarchy Module',
          enter: (_) => _actions.changeToPanel(7),
          preLeave: (RoutePreLeaveEvent e) =>
              e.allowLeave(new Future.value(_stores.panelCanChange)))
      ..addRoute(
          name: 'panel_module${panelInst}',
          path: '/panel',
          pageTitle: 'Panel Example: Panel Module',
          enter: (RouteEnterEvent e) async {
            await _actions.changeToPanel(8);
            PanelModule panelMod = _stores.panelModule as PanelModule;
            panelMod.router.attachToRouter(router, startingFrom: e.route);
          },
          preLeave: (RoutePreLeaveEvent e) {
            // TODO - do we need to un-attach?
            bool panelCanChange = _stores.panelCanChange;
            if (panelCanChange) {
              PanelModule panelMod = _stores.panelModule as PanelModule;
              panelMod.router.detachFromRouter();
            }
            e.allowLeave(new Future.value(panelCanChange));
          },
          factory: (Route mountRoute) async {
            await _actions.changeToPanel(8);
            PanelModule panelMod = _stores.panelModule as PanelModule;
            return panelMod;
          });
  }
}

class PanelComponents implements ModuleComponents {
  PanelActions _actions;
  PanelStore _stores;
  Router _router;

  PanelComponents(this._actions, this._stores, this._router);

  content() => PanelComponent(
      {'actions': _actions, 'store': _stores, 'router': _router});
}

class PanelActions {
  final Action<num> changeToPanel = new Action<num>();
}

class PanelStore extends Store {
  /// Public data
  num _panelIndex = -1;
  num get panelIndex => _panelIndex;
  bool _isRenderable = false;
  bool get isRenderable => _isRenderable;
  Module _panelModule;
  Module get panelModule => _panelModule;

  /// Internals
  Router _router;
  PanelActions _actions;
  LifecycleModule _parentModule;

  PanelModule get parentPanel => _parentModule;

  PanelStore(Router this._router, PanelActions this._actions,
      LifecycleModule this._parentModule) {
    triggerOnAction(_actions.changeToPanel, _changeToPanel);
  }

  bool get panelCanChange {
    // is there a different panel currently loaded?
    if (_panelModule != null) {
      // do we need to reject the unload of the existing panel?
      ShouldUnloadResult canUnload = _panelModule.shouldUnload();
      if (!canUnload.shouldUnload) {
        // notify user of failure
        // TODO - must be a better place for this!
        window.alert(canUnload.messagesAsString());
      }
      return canUnload.shouldUnload;
    }
    return true;
  }

  _changeToPanel(num newPanelIndex) async {
    // ignore changes to the same panel
    if (newPanelIndex == _panelIndex) {
      return;
    }

    // reject changes if necessary
    if (!panelCanChange) {
      return;
    }

    // unload the existing panel
    _isRenderable = false;
    _panelModule?.unload();

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
    await _parentModule.loadChildModule(_panelModule);
    _isRenderable = true;
  }
}

var PanelComponent = react.registerComponent(() => new _PanelComponent());

class _PanelComponent extends FluxComponent<PanelActions, PanelStore> {
  Router get router => props['router'];

  render() {
    // display a loading placeholder if the module isn't ready for rendering
    var content = store.isRenderable
        ? store.panelModule.components.content()
        : react.div({'className': 'loader'}, 'Loading new panel module...');

    var tabBar = react.div({
      'className': 'buttonBar'
    }, [
      // TODO - temp label to identify panel instance
      react.button({
        'key': 'panelInst',
        'style': {'backgroundColor': 'greenyellow'}
      }, '${store.parentPanel.panelInst}'),

      _renderPanelButton(0, 'Basic', '/basic'),
      _renderPanelButton(1, 'Flux', '/flux'),
      _renderPanelButton(2, 'Reject', '/reject'),
      _renderPanelButton(3, 'Data Load (async)', '/dataLoad_async'),
      _renderPanelButton(4, 'Data Load (blocking)', '/dataLoad_blocking'),
      _renderPanelButton(5, 'Deferred', '/deferred'),
      _renderPanelButton(6, 'Lifecycle Echo', '/lifecycle_echo'),
      _renderPanelButton(7, 'All of them', '/hierarchy'),
      _renderPanelButton(8, 'Recursive', '/panel')

      // changeRoute version
//      _renderPanelButton(0, 'Basic', 'basic_module'),
//      _renderPanelButton(1, 'Flux', 'flux_module'),
//      _renderPanelButton(2, 'Reject', 'reject_module'),
//      _renderPanelButton(3, 'Data Load (async)', 'dataLoad_async_module'),
//      _renderPanelButton(4, 'Data Load (blocking)', 'dataLoad_blocking_module'),
//      _renderPanelButton(5, 'Deferred', 'deferred_module'),
//      _renderPanelButton(6, 'Lifecycle Echo', 'lifecycle_echo_module'),
//      _renderPanelButton(7, 'All of them', 'hierarchy_module'),
//      _renderPanelButton(8, 'Recursive', 'panel_module')
    ]);

    return react.div({
      'style': {
        'padding': '5px',
        'backgroundColor': 'white',
        'color': 'black',
        'border': '1px solid lightgreen'
      }
    }, [
      tabBar,
      content
    ]);
  }

  _renderPanelButton(int index, String label, String url) {
    return react.button({
      'key': index,
      'onClick': (_) => router.gotoUrl(url),
//      'onClick': (_) => router.changeRoute(url),
      'className': store.panelIndex == index ? 'active' : null
    }, label);
  }
}
