library w_module.example.panel.deferred_module;

import 'dart:async';

import 'package:react/react.dart' as react;
import 'package:web_skin_react/web_skin_react.dart' as WSR;

import './panel_content.dart';
import './deferred_heavyLifter_interface.dart';
import './deferred_heavyLifter_implementation.dart' deferred as HeavyLifterWithData;

class DeferredModule extends PanelContent {
  final String name = 'DeferredModule';

  HeavyLifter data;

  DeferredComponents _components;
  DeferredComponents get components => _components;

  DeferredModule() {
    _components = new DeferredComponents(this);
  }

  Future onLoad() async {
    await HeavyLifterWithData.loadLibrary();
    data = new HeavyLifterWithData.RealLifter(HeavyLifterDivision.HEAVYWEIGHT);
  }
}

class DeferredComponents implements PanelContentComponents {
  DeferredModule _module;
  DeferredComponents(this._module);

  content() {
    int keyCounter = 0;
    return react.div({'style': {'padding': '50px', 'backgroundColor': 'blue', 'color': 'white'}}, [
      'This module gets its data from a deferred implementation.',
      WSR.ListGroup({},
          _module.data.competitors.map((item) => WSR.ListGroupItem({'key': keyCounter++}, item)))
    ]);
  }
}
