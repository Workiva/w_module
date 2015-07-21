// GENERATED CODE - DO NOT MODIFY BY HAND
// 2015-07-21T20:19:49.542Z

part of w_module.example.deferred.deferred_example_module;

// **************************************************************************
// Generator: DeferredModuleGenerator
// Target: library w_module.example.deferred.deferred_example_module
// **************************************************************************

abstract class ExampleApi {
  Future doStuffWith(String stuff, {dynamic quiet});
}

abstract class ExampleComponents {
  dynamic content([String content]);
}

abstract class ExampleEvents {
  Stream things;
}

class DeferredExampleModule extends Module {
  String get name {
    if (!_isLoaded) return 'DeferredExampleModule';
    return _actual.name;
  }

  var _actual;
  bool _isLoaded = false;

  ExampleApi get api {
    _verifyIsLoaded();
    return _actual.api;
  }

  ExampleComponents get components {
    _verifyIsLoaded();
    return _actual.components;
  }

  ExampleEvents get events {
    _verifyIsLoaded();
    return _actual.events;
  }

  Future onLoad() async {
    await example_module.loadLibrary();
    _actual = new example_module.ExampleModule();
    _isLoaded = true;
  }

  Future<bool> shouldUnload() {
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
