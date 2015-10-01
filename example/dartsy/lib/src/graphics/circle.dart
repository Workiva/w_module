part of dartsy.graphics;

class Circle extends Ellipse {

  Circle.fromPoints(Point anchor, Point focus): super.fromPoints(anchor, focus) {
    var rectangle = new Rectangle.fromPoints(anchor, focus);
    var sideLength = max(rectangle.width, rectangle.height);
    var radius = radiusX = radiusY = sideLength / 2;
    centerX = rectangle.left + radius;
    centerY = rectangle.top + radius;
  }
}
