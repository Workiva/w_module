library w_module.src.view_module;

import 'module.dart';

abstract class ViewModuleMixin {
  buildComponent();
}

abstract class ViewModule extends Module with ViewModuleMixin {}

abstract class ViewModuleWithToolbar extends ViewModule {
  buildToolbarComponent();
}
