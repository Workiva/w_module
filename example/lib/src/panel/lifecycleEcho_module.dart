
library w_module.example.panel.lifecycleEcho_module;

import 'dart:async';

import 'package:w_module/w_module.dart';
import 'package:react/react.dart' as react;


class LifecycleEchoModule extends ViewModule {

  final String name = 'LifecycleEchoModule';

  // TODO - remove once updated
  get api => null;
  get events => null;

  buildComponent() => react.div({
    'style': {
      'padding': '50px',
      'backgroundColor': 'lightGray',
      'color': 'black'
    }
  }, [
    'This module echoes all of its lifecycle events to the dev console.'
  ]);

  LifecycleEchoModule() {
    // Callbacks that can be overridden to be notified of lifecycle changes
    willLoad = () { print('${name}: willLoad'); };
    didLoad = () { print('${name}: didLoad'); };
    willUnload = () { print('${name}: willUnload'); };
    didUnload = () { print('${name}: didUnload'); };
  }

  //--------------------------------------------------------
  // Methods that can be optionally implemented by subclasses
  // to execute code during certain phases of the module
  // lifecycle
  //--------------------------------------------------------

  Future onLoad() async {
    print('${name}: onLoad');
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
