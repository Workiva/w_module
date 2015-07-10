
library w_module.example.panel.dataLoadBlocking_module;

import 'dart:async';

import 'package:w_module/w_module.dart';
import 'package:react/react.dart' as react;
import 'package:web_skin_react/web_skin_react.dart' as WSR;


class DataLoadBlockingModule extends ViewModule {

  final String name = 'DataLoadBlockingModule';

  // TODO - remove once updated
  get api => null;
  get events => null;

  buildComponent() => react.div({
    'style': {
      'padding': '50px',
      'backgroundColor': 'red',
      'color': 'white'
    }
  }, [
    'This module blocks the module loading lifecycle until the data is ready to render.',
    WSR.ListGroup({}, data.map((item) => WSR.ListGroupItem({}, item)))
  ]);

  List<String> data;

  DataLoadBlockingModule() {
    data = [];
  }

  onLoad() async {
    // perform async load of data (fake it with a Future)
    await new Future.delayed(new Duration(seconds: 1));
    data = [
      'Grover',
      'Hoffman',
      'Lessard',
      'Peterson',
      'Udey',
      'Weible'
    ];
  }

}
