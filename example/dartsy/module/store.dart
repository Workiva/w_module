library w_module.example.dartsy.module.store;

import 'package:w_flux/w_flux.dart';
import 'package:rate_limit/rate_limit.dart';
import '../lib/dartsy.dart' as Dartsy;
import './actions.dart';

class ShapeSettings {

  String fill;
  num fillOpacity;
  String stroke;
  num strokeWidth;
  String strokeLinecap;
  List<num> strokeDashArray;
  num strokeOpacity;
  String shapeType;

  ShapeSettings();

}


class DartsyStore extends Store {

  Dartsy.Module _dartsy;
  DartsyActions _actions;
  num selectedShapeKey;

  // ShapeSettings and Dartsy.Graphic don't have exposed types
  get shapeSettings => _dartsy.shapeSettings;
  List<Dartsy.Shape> get graphics => _dartsy.graphicStore.graphics;
  Dartsy.Shape get selectedShape => _dartsy.selectionStore.selection;

  get drawingComponent => _dartsy.component;

  // works, but seems awkward
  DartsyStore(this._actions) : super(transformer: new Throttler(const Duration(milliseconds: 30))) {
//  DartsyStore(this._actions) {  // if used without a transformer

    // initialize a new Dartsy component with default settings
    _dartsy = new Dartsy.Module(new Dartsy.Configuration('example-drawing'));
    _dartsy.shapeSettings
      ..shapeType = Dartsy.Shapes.CIRCLE
      ..fill = '#cfe2f3'
      ..fillOpacity = 1
      ..stroke = '#000000'
      ..strokeWidth = 5
      ..strokeOpacity = 1
      ..strokeLinecap = 'butt'
      ..strokeDashArray = [];
    selectedShapeKey = -1;

    // if shapeSettings was some sort of observable -> changes could be made to it directly and trigger to be reflected elsewhere with less code

    // !!! TODO - Getting extra triggers on certain operations - must diagnose and fix !!!

    // shape operations

    triggerOnAction(_actions.setShapeType,        (String payload)    => _dartsy.shapeSettings.shapeType = payload);
    triggerOnAction(_actions.setFillOpacity,      (double payload)    => _dartsy.shapeSettings.fillOpacity = payload);
    triggerOnAction(_actions.setStrokeOpacity,    (double payload)    => _dartsy.shapeSettings.strokeOpacity = payload);
    triggerOnAction(_actions.setStrokeWidth,      (int payload)       => _dartsy.shapeSettings.strokeWidth = payload);
    triggerOnAction(_actions.setStrokeLinecap,    (String payload)    => _dartsy.shapeSettings.strokeLinecap = payload);
    triggerOnAction(_actions.setStrokeDashArray,  (List<num> payload) => _dartsy.shapeSettings.strokeDashArray = payload);

    // throttle the color change streams

//    var throttledFillColor = _actions.setFillColor.transform(new Throttler(const Duration(milliseconds: 30)));
//    triggerOnAction(throttledFillColor, (String payload) => _dartsy.shapeSettings.fill = payload);
//    var throttledStrokeColor = _actions.setStrokeColor.transform(new Throttler(const Duration(milliseconds: 30)));
//    triggerOnAction(throttledStrokeColor, (String payload) => _dartsy.shapeSettings.stroke = payload);
    triggerOnAction(_actions.setFillColor, (String payload) => _dartsy.shapeSettings.fill = payload);
    triggerOnAction(_actions.setStrokeColor, (String payload) => _dartsy.shapeSettings.stroke = payload);

    // graphic stack operations

    triggerOnAction(_actions.setSelectedShape,          (Dartsy.Shape shape) => _dartsy.selectionStore.selection = shape);
    triggerOnAction(_actions.clearShapes,               (_) => _dartsy.graphicStore.clear());
    triggerOnAction(_actions.removeSelectedShape,       (_) => _dartsy.graphicStore.remove(selectedShape));
    triggerOnAction(_actions.bringSelectedShapeForward, (_) => _dartsy.graphicStore.bringForward(selectedShape));
    triggerOnAction(_actions.bringSelectedShapeToFront, (_) => _dartsy.graphicStore.bringToFront(selectedShape));
    triggerOnAction(_actions.sendSelectedShapeBackward, (_) => _dartsy.graphicStore.sendBackward(selectedShape));
    triggerOnAction(_actions.sendSelectedShapeToBack,   (_) => _dartsy.graphicStore.sendToBack(selectedShape));

    // dartsy event stream subscriptions
    triggerOnAction(_dartsy.actions.graphicStoreChanged);
    triggerOnAction(_dartsy.actions.selectionChanged, onSelectionChange);

  }

  void onSelectionChange(_) {

    Dartsy.Shape curShape = selectedShape;
    num curKey = (curShape == null) ? -1 : curShape.key;

    // show the currently selected shape's styles in the toolbars
    if ((curShape != null) && (curKey != selectedShapeKey)) {

      // must grab all of the settings at once before applying any of them
      // because setting 1 value auto-updates the shape
      // TODO - fix that ^^^
      String currentShape = Dartsy.Shapes.RECT;
      if (curShape is Dartsy.Circle) {
        currentShape = Dartsy.Shapes.CIRCLE;
      } else if (curShape is Dartsy.Ellipse) {
        currentShape = Dartsy.Shapes.ELLIPSE;
      } else if (curShape is Dartsy.Square) {
        currentShape = Dartsy.Shapes.SQUARE;
      } else if (curShape is Dartsy.Line) {
        currentShape = Dartsy.Shapes.LINE;
      }

      ShapeSettings newSettings = new ShapeSettings()
        ..shapeType = currentShape
        ..fill = curShape.fill
        ..fillOpacity = curShape.fillOpacity
        ..stroke = curShape.stroke
        ..strokeWidth = curShape.strokeWidth
        ..strokeOpacity = curShape.strokeOpacity
        ..strokeLinecap = curShape.strokeLinecap
        ..strokeDashArray = curShape.strokeDashArray;

      _dartsy.shapeSettings
        ..shapeType = newSettings.shapeType
        ..fill = newSettings.fill
        ..fillOpacity = newSettings.fillOpacity
        ..stroke = newSettings.stroke
        ..strokeWidth = newSettings.strokeWidth
        ..strokeOpacity = newSettings.strokeOpacity
        ..strokeLinecap = newSettings.strokeLinecap
        ..strokeDashArray = newSettings.strokeDashArray;

    }

    selectedShapeKey = curKey;
  }

}
