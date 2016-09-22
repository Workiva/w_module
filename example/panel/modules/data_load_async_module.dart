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

library w_module.example.panel.modules.data_load_async_module;

import 'dart:async';

import 'package:meta/meta.dart' show protected;
import 'package:react/react.dart' as react;
import 'package:w_flux/w_flux.dart';
import 'package:w_module/w_module.dart';

class DataLoadAsyncModule extends Module {
  @override
  final String name = 'DataLoadAsyncModule';

  DataLoadAsyncActions _actions;
  DataLoadAsyncComponents _components;
  DataLoadAsyncStore _stores;

  DataLoadAsyncModule() {
    _actions = new DataLoadAsyncActions();
    _stores = new DataLoadAsyncStore(_actions);
    _components = new DataLoadAsyncComponents(_actions, _stores);
  }

  @override
  DataLoadAsyncComponents get components => _components;

  @override
  @protected
  Future<Null> onLoad() {
    // trigger non-blocking async load of data
    _actions.loadData();
    return new Future.value();
  }
}

class DataLoadAsyncComponents implements ModuleComponents {
  DataLoadAsyncActions _actions;
  DataLoadAsyncStore _stores;

  DataLoadAsyncComponents(this._actions, this._stores);

  @override
  Object content() =>
      DataLoadAsyncComponent({'actions': _actions, 'store': _stores});
}

class DataLoadAsyncActions {
  final Action loadData = new Action();
}

class DataLoadAsyncStore extends Store {
  DataLoadAsyncActions _actions;
  List<String> _data;
  bool _isLoading;

  DataLoadAsyncStore(this._actions) {
    _isLoading = false;
    _data = [];
    triggerOnAction(_actions.loadData, _loadData);
  }

  /// Public data
  List<String> get data => _data;

  bool get isLoading => _isLoading;

  Future<Null> _loadData(_) async {
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

// ignore: non_constant_identifier_names
Object DataLoadAsyncComponent =
    react.registerComponent(() => new _DataLoadAsyncComponent());

class _DataLoadAsyncComponent
    extends FluxComponent<DataLoadAsyncActions, DataLoadAsyncStore> {
  @override
  Object render() {
    var content;
    if (store.isLoading) {
      content = react.div({'className': 'loader'}, 'Loading data...');
    } else {
      int keyCounter = 0;
      content = react.ul({'className': 'list-group'},
          store.data.map((item) => react.li({'key': keyCounter++}, item)));
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
