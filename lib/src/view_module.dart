library w_module.src.view_module;

import 'module.dart';

abstract class ViewModule extends Module {
  buildComponent();
}

abstract class ViewModuleWithToolbar extends ViewModule {
  buildToolbarComponent();
}
