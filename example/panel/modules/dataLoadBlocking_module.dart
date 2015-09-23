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

library w_module.example.panel.modules.dataLoadBlocking_module;

import 'dart:async';

import 'package:react/react.dart' as react;
import 'package:w_module/w_module.dart';

class DataLoadBlockingModule extends Module {
  final String name = 'DataLoadBlockingModule';

  List<String> data;

  DataLoadBlockingComponents _components;
  DataLoadBlockingComponents get components => _components;

  DataLoadBlockingModule() {
    data = [];
    _components = new DataLoadBlockingComponents(this);
  }

  Future onLoad() async {
    // perform async load of data (fake it with a Future)
    await new Future.delayed(new Duration(seconds: 1));
    data = ['Grover', 'Hoffman', 'Lessard', 'Peterson', 'Udey', 'Weible'];
  }
}

class DataLoadBlockingComponents implements ModuleComponents {
  DataLoadBlockingModule _module;
  DataLoadBlockingComponents(this._module);

  content() {
    int keyCounter = 0;
    return react.div({
      'style': {'padding': '50px', 'backgroundColor': 'red', 'color': 'white'}
    }, [
      'This module blocks the module loading lifecycle until the data is ready to render.',
      react.ul({'className': 'list-group'},
          _module.data.map((item) => react.li({'key': keyCounter++}, item)))
    ]);
  }
}
