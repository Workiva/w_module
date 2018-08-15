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

library w_module.example.panel.modules.basic_module;

import 'package:react/react.dart' as react;
import 'package:w_module/w_module.dart';

class BasicModule extends Module {
  @override
  final String name = 'BasicModule';

  BasicModuleComponents _components;

  BasicModule() {
    _components = new BasicModuleComponents();
  }

  @override
  BasicModuleComponents get components => _components;
}

class BasicModuleComponents implements ModuleComponents {
  @override
  Object content() => react.div({
        'style': {
          'padding': '50px',
          'backgroundColor': 'lightgray',
          'color': 'black'
        }
      }, 'This module does almost nothing.');
}
