part of dartsy.graphics;

class Line extends Shape {
  num x1 = 0;
  num y1 = 0;
  num x2 = 0;
  num y2 = 0;

  Line.fromPoints(Point anchor, Point focus) {
    x1 = anchor.x;
    y1 = anchor.y;
    x2 = focus.x;
    y2 = focus.y;
  }

  Rectangle getBoundingBox() =>
      new Rectangle.fromPoints(new Point(x1, y1), new Point(x2, y2));
}
