part of dartsy.context;

typedef void GraphicUpdateCallback(Graphic graphic);

class GraphicStore extends Store {
  Context _context;
  List<Graphic> _graphics = [];

  GraphicStore(this._context);

  List<Graphic> get graphics => _graphics;

  Graphic getByKey(int key) {
    return _graphics.firstWhere((g) => g.key == key, orElse: () => null);
  }

  void clear() {
    _graphics
      ..forEach((g) => _context.actions.graphicRemoved(g))
      ..clear()
    ;
    _context.actions.graphicStoreChanged();
  }

  void add(Graphic graphic) {
    _applyStyles(graphic);
    _graphics.add(graphic);
    _context.actions.graphicStoreChanged();
  }

  void remove(Graphic graphic) {
    _context.actions.graphicRemoved(graphic);
    _graphics.remove(graphic);
    _context.actions.graphicStoreChanged();
  }

  void updateStyles(Graphic graphic) {
    _applyStyles(graphic);
    _context.actions.graphicChanged(graphic);
  }

  void move(Graphic graphic, num dx, num dy) {
    _move(graphic, dx, dy);
    _context.actions.graphicChanged(graphic);
  }

  Point resize(Graphic graphic, Point anchor, Point focus, {bool preserveAspectRatio: false}) {
    var angle = graphic.angle;
    var origin = graphic.getCenterPoint();
    if (angle != 0) {
      focus = getRotatedPoint(focus, origin, -angle);
    }
    _resize(graphic, anchor, focus,
        preserveAspectRatio || graphic is Circle || graphic is Square);
    // If rotated, move the graphic so the resize origin stays put.
    if (angle != 0) {
      var centerPoint = graphic.getCenterPoint();
      var rotatedCenterPoint = getRotatedPoint(centerPoint, origin, angle);
      var dx = rotatedCenterPoint.x - centerPoint.x;
      var dy = rotatedCenterPoint.y - centerPoint.y;
      _move(graphic, dx, dy);
    }
    _context.actions.graphicChanged(graphic);
    return focus;
  }

  void rotate(Graphic graphic, Point focus, {bool constrain: false}) {
    var anchor = graphic.getCenterPoint();
    var angle = getAngleBetweenPoints(anchor, focus);
    if (constrain) {
      var nearestFifteenth = (angle ~/ 15) * 15;
      angle = angle % 15 < 7.5 ? nearestFifteenth : nearestFifteenth + 15;
    }
    graphic.angle = angle;
    _context.actions.graphicChanged(graphic);
  }

  void bringForward(Graphic graphic) {
    var indexOf = _graphics.indexOf(graphic);
    _graphics.removeAt(indexOf);
    _graphics.insert(min(_graphics.length, indexOf + 1), graphic);
    _context.actions.graphicStoreChanged();
  }

  void bringToFront(Graphic graphic) {
    _graphics.remove(graphic);
    _graphics.add(graphic);
    _context.actions.graphicStoreChanged();
  }

  void sendBackward(Graphic graphic) {
    var indexOf = _graphics.indexOf(graphic);
    _graphics.removeAt(indexOf);
    _graphics.insert(max(0, indexOf - 1), graphic);
    _context.actions.graphicStoreChanged();
  }

  void sendToBack(Graphic graphic) {
    _graphics.remove(graphic);
    _graphics.insert(0, graphic);
    _context.actions.graphicStoreChanged();
  }

  void _applyStyles(Graphic graphic) {
    if (graphic is Shape) {
      var settings = _context.shapeSettings;
      Shape shape = graphic;
      shape
        ..fill = settings.fill
        ..fillOpacity = settings.fillOpacity
        ..stroke = settings.stroke
        ..strokeWidth = settings.strokeWidth
        ..strokeLinecap = settings.strokeLinecap
        ..strokeDashArray = settings.strokeDashArray
        ..strokeOpacity = settings.strokeOpacity
      ;
    }
  }

  void _move(Graphic graphic, num dx, num dy) {
    if (graphic is Rect) {
      Rect rect = graphic;
      rect.left += dx;
      rect.top += dy;
    }
    else if (graphic is Ellipse) {
      Ellipse ellipse = graphic;
      ellipse.centerX += dx;
      ellipse.centerY += dy;
    }
    else if (graphic is Line) {
      Line line = graphic;
      line.x1 += dx;
      line.y1 += dy;
      line.x2 += dx;
      line.y2 += dy;
    }
  }

  void _resize(Graphic graphic, Point anchor, Point focus, bool preserveAspectRatio) {
    var boundingBox = graphic.getBoundingBox();
    var rectangle = _getNewBoundingRect(anchor, focus, boundingBox, preserveAspectRatio);
    if (graphic is Rect) {
      Rect rect = graphic;
      rect
        ..left = rectangle.left
        ..top = rectangle.top
        ..width = rectangle.width
        ..height = rectangle.height
      ;
    }
    else if (graphic is Ellipse) {
      Ellipse ellipse = graphic;
      ellipse
        ..radiusX = rectangle.width / 2
        ..radiusY = rectangle.height / 2
        ..centerX = rectangle.left + ellipse.radiusX
        ..centerY = rectangle.top + ellipse.radiusY
      ;
    }
    else if (graphic is Line) {
      Line line = graphic;
      if (anchor.x == rectangle.left) {
        line.x1 = rectangle.left;
        line.x2 = rectangle.right;
      } else {
        line.x1 = rectangle.right;
        line.x2 = rectangle.left;
      }
      if (anchor.y == rectangle.top) {
        line.y1 = rectangle.top;
        line.y2 = rectangle.bottom;
      } else {
        line.y1 = rectangle.bottom;
        line.y2 = rectangle.top;
      }
    }
  }
}
