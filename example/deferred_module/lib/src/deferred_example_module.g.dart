// GENERATED CODE - DO NOT MODIFY BY HAND
// 2015-07-22T18:36:33.048Z

part of w_module.example.deferred.deferred_example_module;

// **************************************************************************
// Generator: DeferredModuleGenerator
// Target: library w_module.example.deferred.deferred_example_module
// **************************************************************************

abstract class ExampleApi {
  Future<bool> doStuffWith(String stuff, {dynamic quiet, List<int> data});
}

abstract class ExampleComponents extends ModuleComponents {
  dynamic content([String content]);
}

abstract class ExampleEvents {
  Map<Map<String, int>, Stream<bool>> crazyMap;
  Stream<List<int>> get data;
  Stream<String> things;
}

class DeferredExampleModule extends Module {
  String get name {
    if (!_isLoaded) return 'DeferredExampleModule';
    return _actual.name;
  }

  var _actual;
  bool _isLoaded = false;

  @override
  ExampleApi get api {
    _verifyIsLoaded();
    return _actual.api;
  }

  @override
  ExampleComponents get components {
    _verifyIsLoaded();
    return _actual.components;
  }

  @override
  ExampleEvents get events {
    _verifyIsLoaded();
    return _actual.events;
  }

  Future onLoad() async {
    await Future.wait([example_module.loadLibrary(),]);
    _actual = new example_module.ExampleModule();
    _isLoaded = true;
  }

  ShouldUnloadResult shouldUnload() {
    _verifyIsLoaded();
    return _actual.shouldUnload();
  }

  Future onUnload() {
    _verifyIsLoaded();
    return _actual.onUnload();
  }

  void _verifyIsLoaded() {
    if (!_isLoaded) throw new StateError(
        'Cannot access deferred module\'s API until it has been loaded.');
  }
}
