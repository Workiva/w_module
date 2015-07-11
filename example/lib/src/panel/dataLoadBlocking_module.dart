library w_module.example.panel.dataLoadBlocking_module;

import 'dart:async';

import 'package:react/react.dart' as react;
import 'package:web_skin_react/web_skin_react.dart' as WSR;

import './panel_content.dart';

class DataLoadBlockingModule extends PanelContent {
  final String name = 'DataLoadBlockingModule';

  List<String> data;

  DataLoadBlockingComponents _components;
  DataLoadBlockingComponents get components => _components;

  DataLoadBlockingModule() {
    data = [];
    _components = new DataLoadBlockingComponents(this);
  }

  onLoad() async {
    // perform async load of data (fake it with a Future)
    await new Future.delayed(new Duration(seconds: 1));
    data = ['Grover', 'Hoffman', 'Lessard', 'Peterson', 'Udey', 'Weible'];
  }
}

class DataLoadBlockingComponents implements PanelContentComponents {
  DataLoadBlockingModule _module;
  DataLoadBlockingComponents(this._module);

  content() => react.div({
    'style': {'padding': '50px', 'backgroundColor': 'red', 'color': 'white'}
  }, [
    'This module blocks the module loading lifecycle until the data is ready to render.',
    WSR.ListGroup({}, _module.data.map((item) => WSR.ListGroupItem({}, item)))
  ]);
}
