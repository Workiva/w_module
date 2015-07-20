library w_module.example.panel.reject_module;

import 'package:w_module/w_module.dart';
import 'package:w_flux/w_flux.dart';
import 'package:react/react.dart' as react;
import 'package:web_skin_react/web_skin_react.dart' as WSR;

class RejectModule extends Module {
  final String name = 'RejectModule';

  RejectActions _actions;
  RejectStore _stores;

  RejectComponents _components;
  RejectComponents get components => _components;

  RejectModule() {
    _actions = new RejectActions();
    _stores = new RejectStore(_actions);
    _components = new RejectComponents(_actions, _stores);
  }

  ShouldUnloadResult onShouldUnload() {
    if (_stores.shouldUnload) {
      return new ShouldUnloadResult();
    }
    return new ShouldUnloadResult(false, '${name} won\'t let you leave!');
  }
}

class RejectComponents implements ModuleComponents {
  RejectActions _actions;
  RejectStore _stores;

  RejectComponents(this._actions, this._stores);

  content() => RejectComponent({'actions': _actions, 'stores': _stores});
}

class RejectActions {
  final Action toggleShouldUnload = new Action();
}

class RejectStore extends Store {

  /// Public data
  bool _shouldUnload = true;
  bool get shouldUnload => _shouldUnload;

  /// Internals
  RejectActions _actions;

  RejectStore(RejectActions this._actions) {
    triggerOnAction(_actions.toggleShouldUnload, _toggleShouldUnload);
  }

  _toggleShouldUnload(_) {
    _shouldUnload = !_shouldUnload;
  }
}

var RejectComponent = react.registerComponent(() => new _RejectComponent());
class _RejectComponent extends FluxComponent<RejectActions, RejectStore> {
  bool get shouldUnload => state['shouldUnload'];

  getStoreHandlers() => {stores: _updateRejectStore};

  getInitialState() {
    return {'shouldUnload': true};
  }

  render() {
    return react.div({'style': {'padding': '50px', 'backgroundColor': 'green', 'color': 'white'}}, [
      'This module will reject unloading if the checkbox is cleared.',
      WSR.Input({
        'id': 'rejectModuleCheckbox',
        'type': 'checkbox',
        'label': 'shouldUnload',
        'checked': shouldUnload,
        'onChange': actions.toggleShouldUnload
      })
    ]);
  }

  _updateRejectStore(RejectStore store) {
    setState({'shouldUnload': store.shouldUnload});
  }
}
