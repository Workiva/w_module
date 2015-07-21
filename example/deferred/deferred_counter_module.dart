library w_module.example.deferred_transformer.deferred_counter_module;

import 'package:react/react.dart' as react;
import 'package:w_module/alpha/annotations.dart';
import 'package:w_module/w_module.dart';

import 'counter_module_abstracts.dart';
import 'counter_module.dart' deferred as counter_module;

@DeferredModule('CounterModule', 'counter_module')
class DeferredCounterModule extends Module implements CounterModuleDef {
  static get loadingComponent => react.div({}, 'Loading...');

  @override
  String get name => 'DeferredCounterModule';

  @override
  CounterApiDef get api;

  @override
  CounterComponentsDef get components;

  @override
  CounterEventsDef get events;

  // TODO: use this instead of string arg to DeferredModule annotation
  get deferredLibrary => counter_module.loadLibrary;

  // Construct a standard counter module.
  DeferredCounterModule({int startingCount: 0});

  // Construct a counter module that auto increments by 1 every second.
  DeferredCounterModule.autoIncrement({int startingCount: 0});
}
