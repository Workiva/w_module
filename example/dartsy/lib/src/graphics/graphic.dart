part of dartsy.graphics;

abstract class Graphic {
  static int __key = 0;
  int _key = __key++;

  bool active = false;
  num angle = 0;

  Graphic();

  num get key => _key;

  Rectangle getBoundingBox() => throw new UnimplementedError();

  Point getCenterPoint() {
    var rect = getBoundingBox();
    return new Point(rect.left + rect.width / 2, rect.top + rect.height / 2);
  }
}
