part of dartsy.graphics;

class Square extends Rect {

  Square.fromPoints(Point anchor, Point focus): super.fromPoints(anchor, focus) {
    var rectangle = new Rectangle.fromPoints(anchor, focus);
    var sideLength = max(rectangle.width, rectangle.height);
    left = rectangle.left;
    top = rectangle.top;
    width = height = sideLength;
  }
}
