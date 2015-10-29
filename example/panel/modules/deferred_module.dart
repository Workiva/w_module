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

library w_module.example.panel.modules.deferred_module;

import 'dart:async';

import 'package:react/react.dart' as react;
import 'package:w_module/w_module.dart';

import './deferred_heavyLifter_interface.dart';
import './deferred_heavyLifter_implementation.dart'
    deferred as HeavyLifterWithData;

class DeferredModule extends Module {
  final String name = 'DeferredModule';

  HeavyLifter data;

  DeferredComponents _components;
  DeferredComponents get components => _components;

  DeferredModule() {
    _components = new DeferredComponents(this);
  }

  Future onLoad() async {
    await HeavyLifterWithData.loadLibrary();
    data = new HeavyLifterWithData.RealLifter(HeavyLifterDivision.HEAVYWEIGHT);
  }
}

class DeferredComponents implements ModuleComponents {
  DeferredModule _module;
  DeferredComponents(this._module);

  content() {
    int keyCounter = 0;
    return react.div({
      'style': {'padding': '50px', 'backgroundColor': 'blue', 'color': 'white'}
    }, [
      'This module gets its data from a deferred implementation.',
      react.ul(
          {'className': 'list-group'},
          _module.data.competitors
              .map((item) => react.li({'key': keyCounter++}, item)))
    ]);
  }
}
