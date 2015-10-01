part of dartsy.context;

class CanvasController {
  Context _context;
  _BaseState _currentState;
  _ReadyState _readyState;
  _SelectedState _selectedState;
  _DrawingState _drawingState;
  _ResizingState _resizingState;
  _RotatingState _rotatingState;
  _MovingState _movingState;
  _DisabledState _disabledState;

  CanvasController(this._context) {
    _context.canvasController = this;
    _context.actions
      ..graphicStoreChanged.listen(_handleGraphicStoreChanged)
      ..canvasMouseDown.listen(_handleCanvasMouseDown)
      ..canvasMouseMove.listen(_handleCanvasMouseMove)
      ..canvasMouseUp.listen(_handleCanvasMouseUp)
      ..graphicMouseDown.listen(_handleGraphicMouseDown)
      ..resizeHandleMouseDown.listen(_handleResizeHandleMouseDown)
      ..rotateHandleMouseDown.listen(_handleRotateHandleMouseDown)
    ;
    _readyState = new _ReadyState(_context);
    _selectedState = new _SelectedState(_context);
    _drawingState = new _DrawingState(_context);
    _resizingState = new _ResizingState(_context);
    _rotatingState = new _RotatingState(_context);
    _movingState = new _MovingState(_context);
    _disabledState = new _DisabledState(_context);
    enable();
  }

  void enable() {
    _switchToState(_readyState);
  }

  void disable() {
    _switchToState(_disabledState);
  }

  Future<_BaseState> _switchToState(_BaseState newState) {
    var oldState = _currentState;
    // Disable this controller while transitioning to the new state.
    _currentState = _disabledState;
    if (oldState != null) {
      oldState.exit();
    }
    // Switch on the next tick to let events bubble without affecting new state.
    // For example: if user clicks on graphic, then transitions to selected
    // state, the selected state will immediately receive the same event again
    // after it bubbles to the canvas.
    return new Future(() {
      newState.enter();
      _currentState = newState;
      return newState;
    });
  }

  void _handleGraphicStoreChanged(_) {
    if (_context.selectionStore.selection == null) {
      _switchToState(_readyState);
    } else if (_currentState == _readyState) {
      _switchToState(_selectedState);
    }
  }

  void _handleCanvasMouseDown(MouseEvent event) {
    _currentState.handleCanvasMouseDown(event);
  }

  void _handleCanvasMouseMove(MouseEvent event) {
    _currentState.handleCanvasMouseMove(event);
  }

  void _handleCanvasMouseUp(MouseEvent event) {
    _currentState.handleCanvasMouseUp(event);
  }

  void _handleGraphicMouseDown(GraphicMouseEvent event) {
    _currentState.handleGraphicMouseDown(event);
  }

  void _handleResizeHandleMouseDown(GraphicHandleMouseEvent event) {
    _currentState.handleResizeHandleMouseDown(event);
  }

  void _handleRotateHandleMouseDown(GraphicMouseEvent event) {
    _currentState.handleRotateHandleMouseDown(event);
  }
}
