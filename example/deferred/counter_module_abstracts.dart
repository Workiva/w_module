library w_module.example.deferred_transformer.counter_module_abstracts;

import 'dart:async';

import 'package:w_module/w_module.dart';

import 'pair.dart';

abstract class CounterModuleDef implements Module {
  CounterModuleDef({int startingCount});
  CounterModuleDef.autoIncrement({int startingCount});

  @override
  CounterApiDef get api;

  @override
  CounterComponentsDef get components;

  @override
  CounterEventsDef get events;
}

abstract class CounterApiDef {
  int get count;
  List<Pair<DateTime, int>> get history => [];

  Future<Null> increment({int delta});

  Future<Null> decrement({int delta});

  Future<Null> update(int count);
}

abstract class CounterComponentsDef extends ModuleComponents {}

abstract class CounterEventsDef {
  Event<int> get onCountChange;
}
