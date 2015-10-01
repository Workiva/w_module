library w_module.example.dartsy.module.components.graphic_stack_component;

import 'package:react/react.dart' as react;
import 'package:w_flux/w_flux.dart';
import 'package:web_skin_react/web_skin_react.dart' as WSR;

import '../../lib/dartsy.dart' as Dartsy;

import '../actions.dart';
import '../store.dart';

var GraphicStackComponent = react.registerComponent(() => new _GraphicStack());
class _GraphicStack extends FluxComponent<DartsyActions, DartsyStore> {

  List<Dartsy.Graphic> get _graphics => store.graphics;

  render() {

    // Graphic Stack panel

    var graphicItems = _graphics.reversed.map(
        (g) => GraphicStackItem({
          'key': g.key,
          'graphic': g,
          'selected': store.selectedShape != null && store.selectedShape.key == g.key,
          'onClick': actions.setSelectedShape
        })
    ).toList();

    return WSR.Panel({
      'className': 'dartsy-panel-graphic-stack',
      'header': 'Graphic Stack',
      'collapsible': props['collapsible'] ? true : null,
      'defaultExpanded': true
    }, [
      WSR.ButtonGroup({}, [
        WSR.Button({
          'noText': true,
          'onClick': actions.bringSelectedShapeToFront
        }, WSR.Glyphicon({'glyph': 'chevron-double-up'})),
        WSR.Button({
          'noText': true,
          'onClick': actions.bringSelectedShapeForward
        }, WSR.Glyphicon({'glyph': 'chevron-up'})),
        WSR.Button({
          'noText': true,
          'onClick': actions.sendSelectedShapeBackward
        }, WSR.Glyphicon({'glyph': 'chevron-down'})),
        WSR.Button({
          'noText': true,
          'onClick': actions.sendSelectedShapeToBack
        }, WSR.Glyphicon({'glyph': 'chevron-double-down'})),
        WSR.Button({
          'noText': true,
          'onClick': actions.removeSelectedShape
        }, WSR.Glyphicon({'glyph': 'close'})),
        WSR.Button({
          'noText': true,
          'onClick': actions.clearShapes
        }, WSR.Glyphicon({'glyph': 'trash'}))
      ]),
      WSR.ListGroup({}, graphicItems)
    ]);

  }

}


var GraphicStackItem = react.registerComponent(() => new _GraphicListItem());
class _GraphicListItem extends react.Component {

  Dartsy.Graphic get _graphic => props['graphic'];
  bool get _selected => props['selected'];

  render() {
    var graphic = _graphic;
    return WSR.ListGroupItem({
      'wsStyle': _selected ? 'info' : null,
      'onClick': (_) => props['onClick'](graphic)
    }, [
      '${graphic.key}: ${graphic.runtimeType}'
    ]);
  }
}
