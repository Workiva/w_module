library w_module.example.panel.basic_module;

import 'package:w_module/w_module.dart';
import 'package:react/react.dart' as react;


class BasicModule extends ViewModule {

  final String name = 'BasicModule';

  // TODO - remove once updated
  get api => null;
  get events => null;

  buildComponent() => react.div({
    'style': {
      'padding': '50px',
      'backgroundColor': 'lightgray',
      'color': 'black'
    }
  }, 'This module does almost nothing.');

  BasicModule() {}

}
