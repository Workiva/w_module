part of dartsy.components;

String _getTransformForGraphic(Graphic graphic) {
  if (graphic.angle == 0) {
    return null;
  }
  var origin = graphic.getCenterPoint();
  return 'rotate(${graphic.angle},${origin.x},${origin.y})';
}
