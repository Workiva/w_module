library w_module.src.module;

import 'lifecycle_module.dart';

abstract class Module extends LifecycleModule {
  get api => null;
  ModuleComponents get components => null;
  get events => null;
}

abstract class ModuleComponents {
  content() {}
}
