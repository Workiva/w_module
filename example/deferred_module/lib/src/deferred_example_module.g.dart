// GENERATED CODE - DO NOT MODIFY BY HAND
// 2015-07-22T20:11:45.300Z

part of w_module.example.deferred.deferred_example_module;

// **************************************************************************
// Generator: DeferredModuleGenerator
// Target: library w_module.example.deferred.deferred_example_module
// **************************************************************************

abstract class ExampleApi {
  int i;
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
  String _constructorCalled;
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

  var _ExampleModule_stuff;
  var _ExampleModule_data;
  var _ExampleModule_has;

  DeferredExampleModule(String stuff, List<int> data, {bool has}) {
    _constructorCalled = '';
    _ExampleModule_stuff = stuff;
    _ExampleModule_data = data;
    _ExampleModule_has = has;
  }

  var _ExampleModule_named_i;
  var _ExampleModule_named_j;
  var _ExampleModule_named_k;

  DeferredExampleModule.named(int i, [int j, int k]) {
    _constructorCalled = 'named';
    _ExampleModule_named_i = i;
    _ExampleModule_named_j = j;
    _ExampleModule_named_k = k;
  }

  Future onLoad() async {
    await Future.wait([example_module.loadLibrary(),]);
    _constructActualModule();
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

  void _constructActualModule() {
    if (_constructorCalled == '') {
      _actual = new example_module.ExampleModule(
          _ExampleModule_stuff, _ExampleModule_data, has: _ExampleModule_has);
    }
    if (_constructorCalled == 'named') {
      _actual = new example_module.ExampleModule.named(_ExampleModule_named_i,
          _ExampleModule_named_j, _ExampleModule_named_k);
    }
  }

  void _verifyIsLoaded() {
    if (!_isLoaded) throw new StateError(
        'Cannot access deferred module\'s API until it has been loaded.');
  }
}
