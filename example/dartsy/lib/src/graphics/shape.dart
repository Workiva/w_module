part of dartsy.graphics;

abstract class Shape extends Graphic {
  String fill = 'none';
  num fillOpacity = 1;
  String stroke = 'none';
  num strokeWidth = 0;
  List<num> strokeDashArray;
  String strokeLinecap;
  num strokeOpacity = 1;

  Shape();

  factory Shape.fromPoints(String type, Point anchor, Point focus) {
    switch (type) {
      case Shapes.SQUARE:
        return new Square.fromPoints(anchor, focus);
      case Shapes.RECT:
        return new Rect.fromPoints(anchor, focus);
      case Shapes.CIRCLE:
        return new Circle.fromPoints(anchor, focus);
      case Shapes.ELLIPSE:
        return new Ellipse.fromPoints(anchor, focus);
      case Shapes.LINE:
        return new Line.fromPoints(anchor, focus);
      default:
        throw new ArgumentError('type "$type" is unsupported.');
    }
  }
}
