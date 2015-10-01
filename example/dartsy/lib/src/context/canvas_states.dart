part of dartsy.context;

abstract class _BaseState {
  Context _context;
  CanvasController _controller;

  _BaseState(this._context) {
    _controller = _context.canvasController;
  }

  String get name;

  void enter() {}
  void exit() {}
  void handleCanvasMouseDown(MouseEvent event) {}
  void handleCanvasMouseMove(MouseEvent event) {}
  void handleCanvasMouseUp(MouseEvent event) {}
  void handleGraphicMouseDown(GraphicMouseEvent event) {}
  void handleResizeHandleMouseDown(GraphicHandleMouseEvent event) {}
  void handleRotateHandleMouseDown(GraphicMouseEvent event) {}
}

class _ReadyState extends _BaseState {

  _ReadyState(Context context): super(context);

  String get name => 'ready';

  void handleCanvasMouseDown(MouseEvent event) {
    var point = _getPointFromMouseEvent(event, _context.container);
    _controller._switchToState(_controller._drawingState)
        .then((_DrawingState state) => state.startPoint = point);
  }

  void handleGraphicMouseDown(GraphicMouseEvent event) {
    var point = _getPointFromMouseEvent(event.mouseEvent, _context.container);
    _context.selectionStore.selection = event.graphic;
    _controller._switchToState(_controller._movingState)
        .then((_MovingState state) => state.lastMovePoint = point);
  }
}

class _SelectedState extends _BaseState {

  _SelectedState(Context context): super(context);

  String get name => 'selected';

  void handleCanvasMouseDown(MouseEvent event) {
    var point = _getPointFromMouseEvent(event, _context.container);
    _context.selectionStore.selection = null;
    _controller._switchToState(_controller._drawingState)
        .then((_DrawingState state) => state.startPoint = point);
  }

  void handleGraphicMouseDown(GraphicMouseEvent event) {
    var point = _getPointFromMouseEvent(event.mouseEvent, _context.container);
    _context.selectionStore.selection = event.graphic;
    _controller._switchToState(_controller._movingState)
        .then((_MovingState state) => state.lastMovePoint = point);
  }

  void handleResizeHandleMouseDown(GraphicHandleMouseEvent event) {
    _controller._switchToState(_controller._resizingState)
        .then((_ResizingState state) => state.handle = event.handle);
  }

  void handleRotateHandleMouseDown(GraphicMouseEvent event) {
    _controller._switchToState(_controller._rotatingState);
  }
}

class _DrawingState extends _BaseState {
  Point startPoint;

  _DrawingState(Context context): super(context);

  String get name => 'drawing';

  void handleCanvasMouseMove(MouseEvent event) {
    var point = _getPointFromMouseEvent(event, _context.container);
    var shapeType = _context.shapeSettings.shapeType;
    var shape = new Shape.fromPoints(shapeType, startPoint, point);
    _context.graphicStore.add(shape);
    _context.selectionStore.selection = shape;
    _controller._switchToState(_controller._resizingState)
        .then((_ResizingState state) => state.handle = Directions.SE);
  }

  void handleCanvasMouseUp(MouseEvent event) {
    if (_context.selectionStore.selection == null) {
      _controller._switchToState(_controller._readyState);
    } else {
      _controller._switchToState(_controller._selectedState);
    }
  }
}

class _ResizingState extends _BaseState {
  Point _anchorPoint;
  String _handle;

  _ResizingState(Context context): super(context);

  String get handle => _handle;
  set handle(String value) {
    var boundingBox = _context.selectionStore.selection.getBoundingBox();
    _anchorPoint = _getAnchorPointForResizeHandle(value, boundingBox);
    _handle = value;
  }

  String get name => 'resizing';

  void handleCanvasMouseMove(MouseEvent event) {
    var point = _getPointFromMouseEvent(event, _context.container);
    var graphic = _context.selectionStore.selection;
    var unrotatedPoint = _context.graphicStore.resize(
        graphic, _anchorPoint, point, preserveAspectRatio: event.shiftKey);
    // Adjust the handle as the anchor point has changed due to rotation.
    if (unrotatedPoint != point) {
      handle = _getDirectionFromPoints(_anchorPoint, unrotatedPoint);
    }
  }

  void handleCanvasMouseUp(MouseEvent event) {
    _controller._switchToState(_controller._selectedState);
  }
}

class _MovingState extends _BaseState {
  Point lastMovePoint;

  _MovingState(Context context): super(context);

  String get name => 'moving';

  void handleCanvasMouseMove(MouseEvent event) {
    var movePoint = _getPointFromMouseEvent(event, _context.container);
    var dx = movePoint.x - lastMovePoint.x;
    var dy = movePoint.y - lastMovePoint.y;
    var graphic = _context.selectionStore.selection;
    _context.graphicStore.move(graphic, dx, dy);
    lastMovePoint = movePoint;
  }

  void handleCanvasMouseUp(MouseEvent event) {
    _controller._switchToState(_controller._selectedState);
  }
}

class _RotatingState extends _BaseState {

  _RotatingState(Context context): super(context);

  String get name => 'rotating';

  void handleCanvasMouseMove(MouseEvent event) {
    var movePoint = _getPointFromMouseEvent(event, _context.container);
    var graphic = _context.selectionStore.selection;
    _context.graphicStore.rotate(graphic, movePoint, constrain: event.shiftKey);
  }

  void handleCanvasMouseUp(MouseEvent event) {
    _controller._switchToState(_controller._selectedState);
  }
}

class _DisabledState extends _BaseState {

  _DisabledState(Context context): super(context);

  String get name => 'disabled';
}
