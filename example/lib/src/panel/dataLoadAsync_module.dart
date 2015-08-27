library w_module.example.panel.dataLoadAsync_module;

import 'dart:async';

import 'package:w_flux/w_flux.dart';
import 'package:react/react.dart' as react;
import 'package:web_skin_react/web_skin_react.dart' as WSR;
import 'package:w_module/w_module.dart';

class DataLoadAsyncModule extends Module {
  final String name = 'DataLoadAsyncModule';

  DataLoadAsyncActions _actions;
  DataLoadAsyncStore _stores;

  DataLoadAsyncComponents _components;
  DataLoadAsyncComponents get components => _components;

  DataLoadAsyncModule() {
    _actions = new DataLoadAsyncActions();
    _stores = new DataLoadAsyncStore(_actions);
    _components = new DataLoadAsyncComponents(_actions, _stores);
  }

  Future onLoad() async {
    // trigger non-blocking async load of data
    _actions.loadData();
  }
}

class DataLoadAsyncComponents implements ModuleComponents {
  DataLoadAsyncActions _actions;
  DataLoadAsyncStore _stores;

  DataLoadAsyncComponents(this._actions, this._stores);

  content() => DataLoadAsyncComponent({'actions': _actions, 'store': _stores});
}

class DataLoadAsyncActions {
  final Action loadData = new Action();
}

class DataLoadAsyncStore extends Store {
  /// Public data
  bool _isLoading;
  bool get isLoading => _isLoading;
  List<String> _data;
  List<String> get data => _data;

  /// Internals
  DataLoadAsyncActions _actions;

  DataLoadAsyncStore(DataLoadAsyncActions this._actions) {
    _isLoading = false;
    _data = [];
    triggerOnAction(_actions.loadData, _loadData);
  }

  _loadData(_) async {
    // set loading state and trigger to display loading spinner
    _isLoading = true;
    trigger();

    // start async load of data (fake it with a Future)
    await new Future.delayed(new Duration(seconds: 1));

    // trigger on return of final data
    _data = ['Aaron', 'Dustin', 'Evan', 'Jay', 'Max', 'Trent'];
    _isLoading = false;
  }
}

var DataLoadAsyncComponent =
    react.registerComponent(() => new _DataLoadAsyncComponent());

class _DataLoadAsyncComponent
    extends FluxComponent<DataLoadAsyncActions, DataLoadAsyncStore> {
  render() {
    var content;
    if (store.isLoading) {
      content = WSR.ProgressBar({
        'wsStyle': 'info',
        'indeterminate': true,
        'label': 'Loading Data...'
      });
    } else {
      int keyCounter = 0;
      content = WSR.ListGroup(
          {},
          store.data
              .map((item) => WSR.ListGroupItem({'key': keyCounter++}, item)));
    }

    return react.div({
      'style': {
        'padding': '50px',
        'backgroundColor': 'orange',
        'color': 'white'
      }
    }, [
      'This module renders a loading spinner until data is ready for display.',
      content
    ]);
  }
}
