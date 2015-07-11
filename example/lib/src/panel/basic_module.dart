library w_module.example.panel.basic_module;

import 'package:react/react.dart' as react;

import './panel_content.dart';

class BasicModule extends PanelContent {
  final String name = 'BasicModule';

  BasicModuleComponents _components;
  BasicModuleComponents get components => _components;

  BasicModule() {
    _components = new BasicModuleComponents();
  }
}

class BasicModuleComponents implements PanelContentComponents {
  BasicModuleComponents();

  content() => react.div({
    'style': {'padding': '50px', 'backgroundColor': 'lightgray', 'color': 'black'}
  }, 'This module does almost nothing.');
}
