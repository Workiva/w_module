library w_module.example.deferred.example_module;

import 'dart:async';

import 'package:w_module/w_module.dart';

class ExampleModule extends Module {
  @override
  ExampleApi get api => new ExampleApi();

  @override
  ExampleComponents get components => new ExampleComponents();

  @override
  ExampleEvents get events => new ExampleEvents();
}

class ExampleApi {
  Future<bool> doStuffWith(String stuff, {quiet: false}) async {
    if (quiet) return false;
    print(stuff);
    return true;
  }
}

class ExampleComponents {
  content([String content = 'Content!']) => content;
}

class ExampleEvents {
  Stream<String> get things => new Stream.fromIterable([]);
  set things(Stream<String> things) {}
}