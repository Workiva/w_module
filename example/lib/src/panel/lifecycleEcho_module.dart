library w_module.example.panel.lifecycleEcho_module;

import 'dart:async';

import 'package:w_module/w_module.dart';
import 'package:react/react.dart' as react;

class LifecycleEchoModule extends Module {
  final String name = 'LifecycleEchoModule';

  LifecycleEchoComponents _components;
  LifecycleEchoComponents get components => _components;

  LifecycleEchoModule() {
    // load / unload state streams
    willLoad.listen((_) {
      print('${name}: willLoad');
    });
    didLoad.listen((_) {
      print('${name}: didLoad');
    });
    willUnload.listen((_) {
      print('${name}: willUnload');
    });
    didUnload.listen((_) {
      print('${name}: didUnload');
    });
    didLoadChildModule.listen((_) {
      print('${name}: didLoadChildModule');
    });
    _components = new LifecycleEchoComponents();
  }

  //--------------------------------------------------------
  // Methods that can be optionally implemented by subclasses
  // to execute code during certain phases of the module
  // lifecycle
  //--------------------------------------------------------

  Future onLoad() async {
    print('${name}: onLoad');
    loadChildModule(new LifecycleEchoChildModule());
    await new Future.delayed(new Duration(seconds: 1));
  }

  ShouldUnloadResult onShouldUnload() {
    print('${name}: onShouldUnload');
    return new ShouldUnloadResult();
  }

  Future onUnload() async {
    print('${name}: onUnload');
    await new Future.delayed(new Duration(seconds: 1));
  }
}

class LifecycleEchoComponents implements ModuleComponents {
  content() => react.div({
        'style': {
          'padding': '50px',
          'backgroundColor': 'lightGray',
          'color': 'black'
        }
      }, [
        'This module echoes all of its lifecycle events to the dev console.'
      ]);
}

class LifecycleEchoChildModule extends Module {

}
