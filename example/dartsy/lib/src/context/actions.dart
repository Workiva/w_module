part of dartsy.context;

class Actions {

  // Model actions
  final Action<Graphic> graphicChanged = new Action<Graphic>();
  final Action<Graphic> graphicRemoved = new Action<Graphic>();
  final Action graphicStoreChanged = new Action();
  final Action selectionChanged = new Action();

  // User interactions
  final Action<MouseEvent> canvasMouseDown = new Action<MouseEvent>();
  final Action<MouseEvent> canvasMouseMove = new Action<MouseEvent>();
  final Action<MouseEvent> canvasMouseUp = new Action<MouseEvent>();
  final Action<GraphicMouseEvent> graphicMouseDown = new Action<GraphicMouseEvent>();
  final Action<GraphicHandleMouseEvent> resizeHandleMouseDown = new Action<GraphicHandleMouseEvent>();
  final Action<GraphicMouseEvent> rotateHandleMouseDown = new Action<GraphicMouseEvent>();
}

// TODO - is there some way to allow an arbitrary number of typed Action params?
// (e.g. Action<String, Graphic, MouseEvent>)
// or do we just need to create a complex type for it?
// is there a shortcut for simple types like this?

class GraphicMouseEvent {
  Graphic graphic;
  MouseEvent mouseEvent;

  GraphicMouseEvent(this.graphic, this.mouseEvent);
}

class GraphicHandleMouseEvent {
  String handle;
  Graphic graphic;
  MouseEvent mouseEvent;

  GraphicHandleMouseEvent(this.handle, this.graphic, this.mouseEvent);
}
