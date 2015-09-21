library w_module.example.panel.modules.basic_module;

import 'package:react/react.dart' as react;
import 'package:w_module/w_module.dart';

class BasicModule extends Module {
  final String name = 'BasicModule';

  BasicModuleComponents _components;
  BasicModuleComponents get components => _components;

  BasicModule() {
    _components = new BasicModuleComponents();
  }
}

class BasicModuleComponents implements ModuleComponents {
  content() => react.div({
        'style': {
          'padding': '50px',
          'backgroundColor': 'lightgray',
          'color': 'black'
        }
      }, 'This module does almost nothing.');
}
