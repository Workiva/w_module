library w_module.src.module;

import 'lifecycle_module.dart';

abstract class Module extends LifecycleModule {
  Object get api;
  Object get events;
}
