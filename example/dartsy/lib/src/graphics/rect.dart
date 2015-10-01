part of dartsy.graphics;

class Rect extends Shape {
  num left = 0;
  num top = 0;
  num width = 0;
  num height = 0;
  num cornerRadiusX = 0;
  num cornerRadiusY = 0;

  Rect.fromPoints(Point anchor, Point focus) {
    var rectangle = new Rectangle.fromPoints(anchor, focus);
    left = rectangle.left;
    top = rectangle.top;
    width = rectangle.width;
    height = rectangle.height;
  }

  Rectangle getBoundingBox() => new Rectangle(left, top, width, height);
}
