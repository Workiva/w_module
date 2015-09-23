/// The w_module library implements a module encapsulation and lifecycle
/// pattern for Dart that interfaces well with the application architecture
/// defined in the w_flux library.
///
/// w_module defines how data should flow in and out of a module, how renderable
/// UI is exposed to consumers, and establishes a common module lifecycle that
/// facilitates dynamic loading / unloading of modules.
library w_module;

export 'src/event.dart';
export 'src/lifecycle_module.dart';
export 'src/module.dart';
