library w_module.example.dartsy.module.components.toolpanel_component;

import 'package:react/react.dart' as react;
import 'package:w_flux/w_flux.dart';
import 'package:web_skin_react/web_skin_react.dart' as WSR;

import '../../lib/dartsy.dart' as Dartsy;

import '../actions.dart';
import '../store.dart';
import '../constants.dart';
import './graphic_stack_component.dart';

var DartsyToolpanelComponent = react.registerComponent(() => new _DartsyToolpanel());
class _DartsyToolpanel extends FluxComponent<DartsyActions, DartsyStore> {

  bool get collapsible => props['collapsible'];

  // NOTE - better to handle this event in a method
  // (instead of => 1 liner), since it's used by multiple components
  void _handleShapeChange(event) {
    actions.setShapeType(event.target.value);
  }

  // NOTE - better to handle this event in a method
  // (instead of => 1 liner), since it's LONG...
  void _handleStrokeDashArrayChange(event) {
    String dashStr = event.target.value;
    if (dashStr == null || dashStr == '') {
      actions.setStrokeDashArray([]);
    } else {
      List<num> dashList = [];
      List<String> strList = dashStr.split(',');
      for (String s in strList) {
        num val = num.parse(s, (_) => null);
        if (val != null) {
          dashList.add(val);
        }
      }
      actions.setStrokeDashArray(dashList);
    }
  }

  render() {

    // Shape panel

    var radioIconStyle = {'marginLeft': -15};
    var radioLabelStyle = {'paddingLeft': 30};

    var shapePanel = WSR.Panel({
      'className': 'dartsy-panel-shape',
      'header': 'Shape',
      'collapsible': collapsible ? true : null,
      'defaultExpanded': true
    }, [
      WSR.Input({'className': 'radio-group-wrapper'}, [
        WSR.Input({
          'type': 'radio',
          'name': 'shapeRadio',
          'id': 'shapeRectangle',
          'value': Dartsy.Shapes.RECT,
          'checked': store.shapeSettings.shapeType == Dartsy.Shapes.RECT,
          'onChange': _handleShapeChange,
          'label': react.span({}, [
            WSR.Glyphicon({'wsSize': 'medium', 'style': radioIconStyle, 'glyph': shapeGlyphs[Dartsy.Shapes.RECT]}),
            react.span({'style': radioLabelStyle}, 'Rectangle')
          ])
        }),
        WSR.Input({
          'type': 'radio',
          'name': 'shapeRadio',
          'id': 'shapeEllipse',
          'value': Dartsy.Shapes.ELLIPSE,
          'checked': store.shapeSettings.shapeType == Dartsy.Shapes.ELLIPSE,
          'onChange': _handleShapeChange,
          'label': react.span({}, [
            WSR.Glyphicon({'wsSize': 'medium', 'style': radioIconStyle, 'glyph': shapeGlyphs[Dartsy.Shapes.ELLIPSE]}),
            react.span({'style': radioLabelStyle}, 'Ellipse')
          ])
        }),
        WSR.Input({
          'type': 'radio',
          'name': 'shapeRadio',
          'id': 'shapeSquare',
          'value': Dartsy.Shapes.SQUARE,
          'checked': store.shapeSettings.shapeType == Dartsy.Shapes.SQUARE,
          'onChange': _handleShapeChange,
          'label': react.span({}, [
            WSR.Glyphicon({'wsSize': 'medium', 'style': radioIconStyle, 'glyph': shapeGlyphs[Dartsy.Shapes.SQUARE]}),
            react.span({'style': radioLabelStyle}, 'Square')
          ])
        }),
        WSR.Input({
          'type': 'radio',
          'name': 'shapeRadio',
          'id': 'shapeCircle',
          'value': Dartsy.Shapes.CIRCLE,
          'checked': store.shapeSettings.shapeType == Dartsy.Shapes.CIRCLE,
          'onChange': _handleShapeChange,
          'label': react.span({}, [
            WSR.Glyphicon({'wsSize': 'medium', 'style': radioIconStyle, 'glyph': shapeGlyphs[Dartsy.Shapes.CIRCLE]}),
            react.span({'style': radioLabelStyle}, 'Circle')
          ])
        }),
        WSR.Input({
          'type': 'radio',
          'name': 'shapeRadio',
          'id': 'shapeLine',
          'value': Dartsy.Shapes.LINE,
          'checked': store.shapeSettings.shapeType == Dartsy.Shapes.LINE,
          'onChange': _handleShapeChange,
          'label': react.span({}, [
            WSR.Glyphicon({'wsSize': 'medium', 'style': radioIconStyle, 'glyph': shapeGlyphs[Dartsy.Shapes.LINE]}),
            react.span({'style': radioLabelStyle}, 'Line')
          ])
        })
      ])
    ]);

    // Style panel

    var stylePanel = WSR.Panel({
      'className': 'dartsy-panel-style',
      'header': 'Style',
      'collapsible': collapsible ? true : null,
      'defaultExpanded': true
    }, [
      WSR.Input({
        'type': 'color',
        'name': 'fill',
        'id': 'fill',
        'label': 'Fill Color',
        'value': store.shapeSettings.fill,
        'onChange': (event) => actions.setFillColor(event.target.value)
      }),
      WSR.Input({
        'type': 'number',
        'name': 'fillOpacity',
        'id': 'fillOpacity',
        'label': 'Fill Opacity',
        'step': 0.1,
        'min': 0,
        'max': 1,
        'value': store.shapeSettings.fillOpacity,
        'onChange': (event) => actions.setFillOpacity(double.parse(event.target.value))
      }),

      WSR.Input({
        'type': 'color',
        'name': 'stroke',
        'id': 'stroke',
        'label': 'Stroke Color',
        'value': store.shapeSettings.stroke,
        'onChange': (event) => actions.setStrokeColor(event.target.value)
      }),
      WSR.Input({
        'type': 'number',
        'name': 'strokeWidth',
        'id': 'strokeWidth',
        'label': 'Stroke Width',
        'min': 0,
        'value': store.shapeSettings.strokeWidth,
        'onChange': (event) => actions.setStrokeWidth(int.parse(event.target.value))
      }),

      WSR.Input({
        'type': 'select',
        'name': 'strokeLinecap',
        'id': 'strokeLinecap',
        'label': 'Stroke Linecap',
        'value': store.shapeSettings.strokeLinecap,
        'onChange': (event) => actions.setStrokeLinecap(event.target.value)
      }, [
        react.option({'value': 'butt'}, 'Butt'),
        react.option({'value': 'round'}, 'Round'),
        react.option({'value': 'square'}, 'Square')
      ]),

      WSR.Input({
        'type': 'text',
        'name': 'strokeDashArray',
        'id': 'strokeDashArray',
        'label': 'Stroke Dash Array',
        'placeholder': 'eg: 10, 5',
        'onChange': _handleStrokeDashArrayChange
      }),

      WSR.Input({
        'type': 'number',
        'name': 'strokeOpacity',
        'id': 'strokeOpacity',
        'label': 'Stroke Opacity',
        'step': 0.1,
        'min': 0,
        'max': 1,
        'value': store.shapeSettings.strokeOpacity,  // TODO - some simpler syntax for state autocompletion
        'onChange': (event) => actions.setStrokeOpacity(double.parse(event.target.value))
      })
    ]);

    // Graphic Stack panel

    var graphicStackPanel = GraphicStackComponent({'store': store, 'actions': actions, 'collapsible': collapsible});

    return WSR.PanelGroup({'className': 'dartsy-toolpanel'}, [
      shapePanel,
      stylePanel,
      graphicStackPanel
    ]);

  }

}
