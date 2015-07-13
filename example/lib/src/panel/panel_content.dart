library w_module.example.panel.panel_content;

import 'package:w_module/w_module.dart';

abstract class PanelContent extends Module {
  PanelContentComponents _components;
  PanelContentComponents get components => _components;
}

abstract class PanelContentComponents {
  content() {}
}
