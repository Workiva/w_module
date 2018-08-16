// Copyright 2017 Workiva Inc.
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

import 'package:meta/meta.dart' show protected;
import 'package:react/react.dart' as react;
import 'package:w_module/w_module.dart';

import './deferred_heavy_lifter_interface.dart';
import './deferred_heavy_lifter_implementation.dart'
    deferred as heavy_lifter_with_data;

class DeferredModule extends Module {
  HeavyLifter data;
  DeferredComponents _components;

  DeferredModule() {
    _components = new DeferredComponents(this);
  }

  @override
  DeferredComponents get components => _components;

  @override
  @protected
  Future<Null> onLoad() async {
    await heavy_lifter_with_data.loadLibrary();
    data =
        new heavy_lifter_with_data.RealLifter(HeavyLifterDivision.heavyweight);
  }
}

class DeferredComponents implements ModuleComponents {
  DeferredModule _module;
  DeferredComponents(this._module);

  @override
  Object content() {
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
