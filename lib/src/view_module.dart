library w_module.src.view_module;

import 'module.dart';


abstract class ViewModule extends Module {
  Object get component;
}

abstract class ViewModuleWithToolbar extends ViewModule {
  Object get toolbar;
}
