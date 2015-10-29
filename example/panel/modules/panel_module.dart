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
import 'package:react/react.dart' as react;

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

  content() => PanelComponent({'actions': _actions, 'store': _stores});
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
    await _parentModule.loadChildModule(_panelModule);
    _isRenderable = true;
  }
}

var PanelComponent = react.registerComponent(() => new _PanelComponent());

class _PanelComponent extends FluxComponent<PanelActions, PanelStore> {
  render() {
    // display a loading placeholder if the module isn't ready for rendering
    var content = store.isRenderable
        ? store.panelModule.components.content()
        : react.div({'className': 'loader'}, 'Loading new panel module...');

    var tabBar = react.div({
      'className': 'buttonBar'
    }, [
      _renderPanelButton(0, 'Basic'),
      _renderPanelButton(1, 'Flux'),
      _renderPanelButton(2, 'Reject'),
      _renderPanelButton(3, 'Data Load (async)'),
      _renderPanelButton(4, 'Data Load (blocking)'),
      _renderPanelButton(5, 'Deferred'),
      _renderPanelButton(6, 'Lifecycle Echo'),
      _renderPanelButton(7, 'All of them'),
      _renderPanelButton(8, 'Recursive')
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

  _renderPanelButton(int index, String label) {
    return react.button({
      'key': index,
      'onClick': (_) => actions.changeToPanel(index),
      'className': store.panelIndex == index ? 'active' : null
    }, label);
  }
}
