library w_module.example.dartsy.module.module;

import 'package:w_module/w_module.dart';

import './actions.dart';
import './store.dart';
import './components/toolbar_component.dart';
import './components/toolpanel_component.dart';

class DartsyModule extends Module {

  /**
   * Internals
   */
  DartsyActions _actions;
  DartsyStore _store;
  DartsyComponents _components;

  DartsyComponents get components => _components;

  DartsyModule() {
    // Construct the internal actions and store
    _actions = new DartsyActions();
    _store = new DartsyStore(_actions);
    _components = new DartsyComponents(_actions, _store);
  }

}

class DartsyComponents implements ModuleComponents {
  DartsyActions _actions;
  DartsyStore _store;

  DartsyComponents(this._actions, this._store);

  // Drawing View Component
  content() => _store.drawingComponent;

  // Toolbar - small version for use in a header menu
  toolbar() => DartsyToolbarComponent({'actions': _actions, 'store': _store});

  // Toolpanel - full size version for use in a side panel
  toolpanel({bool collapsible: true}) => DartsyToolpanelComponent({'actions': _actions, 'store': _store, 'collapsible': collapsible});
}
