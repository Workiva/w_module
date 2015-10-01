part of dartsy.context;

// TODO - separate this settings type from the actual triggering of changes to the currently selected object

class ShapeSettings {
  Context _context;
  String _fill;
  num _fillOpacity;
  String _stroke;
  num _strokeWidth;
  String _strokeLinecap;
  List<num> _strokeDashArray;
  num _strokeOpacity;

  String shapeType;

  ShapeSettings(this._context);

  String get fill => _fill;
  set fill(String value) {
    if (value != _fill) {
      _fill = value;
      _updateSelectedShape((s) => s.fill = _fill);
    }
  }

  num get fillOpacity => _fillOpacity;
  set fillOpacity(num value) {
    if (value != _fillOpacity) {
      _fillOpacity = value;
      _updateSelectedShape((s) => s.fillOpacity = _fillOpacity);
    }
  }

  String get stroke => _stroke;
  set stroke(String value) {
    if (value != _stroke) {
      _stroke = value;
      _updateSelectedShape((s) => s.stroke = _stroke);
    }
  }

  num get strokeWidth => _strokeWidth;
  set strokeWidth(num value) {
    if (value != _strokeWidth) {
      _strokeWidth = value;
      _updateSelectedShape((s) => s.strokeWidth = _strokeWidth);
    }
  }

  String get strokeLinecap => _strokeLinecap;
  set strokeLinecap(String value) {
    if (value != _strokeLinecap) {
      _strokeLinecap = value;
      _updateSelectedShape((s) => s.strokeLinecap = _strokeLinecap);
    }
  }

  List<num> get strokeDashArray => _strokeDashArray;
  set strokeDashArray(List<num> value) {
    if (value != _strokeDashArray) {
      _strokeDashArray = value;
      _updateSelectedShape((s) => s.strokeDashArray = _strokeDashArray);
    }
  }

  num get strokeOpacity => _strokeOpacity;
  set strokeOpacity(num value) {
    if (value != _strokeOpacity) {
      _strokeOpacity = value;
      _updateSelectedShape((s) => s.strokeOpacity = _strokeOpacity);
    }
  }

  void _updateSelectedShape(Function callback) {
    var graphic = _context.selectionStore.selection;
    if (graphic != null) {
      _context.graphicStore.updateStyles(graphic);
    }
  }
}
