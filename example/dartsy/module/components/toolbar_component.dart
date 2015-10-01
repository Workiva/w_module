library w_module.example.dartsy.module.components.toolbar_component;

import 'package:react/react.dart' as react;
import 'package:w_flux/w_flux.dart';
import 'package:web_skin_react/web_skin_react.dart' as WSR;

import '../../lib/dartsy.dart' as Dartsy;

import '../actions.dart';
import '../store.dart';
import '../constants.dart';

var DartsyToolbarComponent = react.registerComponent(() => new _DartsyToolbar());
class _DartsyToolbar extends FluxComponent<DartsyActions, DartsyStore> {

  render() {

    // wrapped in a button and style hacked so that it fits in the ButtonGroup
    var fillColorInput = WSR.Button({
      'noText': true,
      'style': {
        'padding': 0
      }
    },[
      WSR.Input({
        'type': 'color',
        'name': 'fill',
        'value': store.shapeSettings.fill,
        'onChange': (event) => actions.setFillColor(event.target.value),
        'style': {
          'width': 50,
          'height': 32,
          'padding': 5,
          'border': 'none',
          'boxShadow': 'none',
          'backgroundColor': '#f7f7f7'
        }
      })
    ]);

    var shapeIcon = WSR.Glyphicon({
      'wsSize': 'medium',
      'glyph': shapeGlyphs[store.shapeSettings.shapeType]
    });

    var shapeDropdown = WSR.DropdownButton({
      'title': shapeIcon,
      'noText': true,
      'onSelect': (eventKey, _2, _3, _4, _5, _6) => actions.setShapeType(eventKey)
    }, [
      WSR.MenuItem({'eventKey': Dartsy.Shapes.RECT}, [
        WSR.Glyphicon({'wsSize': 'medium', 'glyph': shapeGlyphs[Dartsy.Shapes.RECT]}),
        ' Rectangle'
      ]),
      WSR.MenuItem({'eventKey': Dartsy.Shapes.ELLIPSE}, [
        WSR.Glyphicon({'wsSize': 'medium', 'glyph': shapeGlyphs[Dartsy.Shapes.ELLIPSE]}),
        ' Ellipse'
      ]),
      WSR.MenuItem({'eventKey': Dartsy.Shapes.SQUARE}, [
        WSR.Glyphicon({'wsSize': 'medium', 'glyph': shapeGlyphs[Dartsy.Shapes.SQUARE]}),
        ' Square'
      ]),
      WSR.MenuItem({'eventKey': Dartsy.Shapes.CIRCLE}, [
        WSR.Glyphicon({'wsSize': 'medium', 'glyph': shapeGlyphs[Dartsy.Shapes.CIRCLE]}),
        ' Circle'
      ]),
      WSR.MenuItem({'eventKey': Dartsy.Shapes.LINE}, [
        WSR.Glyphicon({'wsSize': 'medium', 'glyph': shapeGlyphs[Dartsy.Shapes.LINE]}),
        ' Line'
      ])
    ]);

    return react.div({'className': 'dartsy-toolbar'}, [
      WSR.ButtonGroup({'bsSize': 'small', 'style': {'paddingBottom': '10px'}}, [
        shapeDropdown,
        fillColorInput
      ])
    ]);
  }

}
