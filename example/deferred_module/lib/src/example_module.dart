library w_module.example.deferred.example_module;

import 'dart:async';

import 'package:w_module/w_module.dart';

class ExampleModule extends Module {
  int _i;

  @override
  ExampleApi get api => new ExampleApi(_i);

  @override
  ExampleComponents get components => new ExampleComponents();

  @override
  ExampleEvents get events => new ExampleEvents();

  ExampleModule(String stuff, List<int> data, {bool has: true}) {

  }

  ExampleModule.named(int i, [int j, int k]) {
    this._i = i;
  }
}

class ExampleApi {
  int i;
  ExampleApi(this.i);

  Future<bool> doStuffWith(String stuff, {quiet: false, List<int> data}) async {
    if (quiet) return false;
    print('$i - $stuff');
    return true;
  }
}

class ExampleComponents extends ModuleComponents {
  content([String content = 'Content!']) => content;
}

class ExampleEvents {
  Map<Map<String, int>, Stream<bool>> crazyMap = {};
  Stream<List<int>> get data => new Stream.fromIterable([]);
  Stream<String> get things => new Stream.fromIterable([]);
  set things(Stream<String> things) {}
}