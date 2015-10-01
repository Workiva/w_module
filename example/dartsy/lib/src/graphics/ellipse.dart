part of dartsy.graphics;

class Ellipse extends Shape {
  num centerX = 0;
  num centerY = 0;
  num radiusX = 0;
  num radiusY = 0;

  Ellipse.fromPoints(Point anchor, Point focus) {
    var rectangle = new Rectangle.fromPoints(anchor, focus);
    radiusX = rectangle.width / 2;
    radiusY = rectangle.top / 2;
    centerX = rectangle.left + radiusX;
    centerY = rectangle.top + radiusY;
  }

  Rectangle getBoundingBox() =>
      new Rectangle(centerX - radiusX, centerY - radiusY, radiusX * 2, radiusY * 2);
}
