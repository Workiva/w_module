library w_module.example.panel.deferred_module;

import 'package:w_module/w_module.dart';
import 'package:react/react.dart' as react;
import 'package:web_skin_react/web_skin_react.dart' as WSR;

import './deferred_heavyLifter_interface.dart';
import './deferred_heavyLifter_implementation.dart' deferred as HeavyLifterWithData;

class DeferredModule extends ViewModule {

  final String name = 'DeferredModule';

  // TODO - remove once updated
  get api => null;
  get events => null;

  buildComponent() => react.div({
    'style': {
      'padding': '50px',
      'backgroundColor': 'blue',
      'color': 'white'
    }
  }, [
    'This module gets its data from a deferred implementation.',
    WSR.ListGroup({}, data.competitors.map((item) => WSR.ListGroupItem({}, item)))
  ]);

  HeavyLifter data;

  DeferredModule() {}

  onLoad() async {
    await HeavyLifterWithData.loadLibrary();
    data = new HeavyLifterWithData.RealLifter(HeavyLifterDivision.HEAVYWEIGHT);
  }

}
