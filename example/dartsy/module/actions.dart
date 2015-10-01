library w_module.example.dartsy.module.actions;

import 'package:w_flux/w_flux.dart';

import '../lib/dartsy.dart' as Dartsy;

class DartsyActions {

  // Shape Settings

  final Action<String> setShapeType = new Action<String>();
  final Action<String> setFillColor = new Action<String>();
  final Action<double> setFillOpacity = new Action<double>();
  final Action<String> setStrokeColor = new Action<String>();
  final Action<double> setStrokeOpacity = new Action<double>();
  final Action<int> setStrokeWidth = new Action<int>();
  final Action<String> setStrokeLinecap = new Action<String>();
  final Action<List<num>> setStrokeDashArray = new Action<List<num>>();

  // Shape Stack Ops

  final Action<Dartsy.Shape> setSelectedShape = new Action<Dartsy.Shape>();
  final Action clearShapes = new Action();
  final Action removeSelectedShape = new Action();
  final Action bringSelectedShapeForward = new Action();
  final Action bringSelectedShapeToFront = new Action();
  final Action sendSelectedShapeBackward = new Action();
  final Action sendSelectedShapeToBack = new Action();

}
