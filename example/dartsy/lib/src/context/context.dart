part of dartsy.context;

class Context {
  Element container;
  Actions actions;
  GraphicStore graphicStore;
  ShapeSettings shapeSettings;
  SelectionStore selectionStore;
  CanvasController canvasController;

  Context(Configuration configuration) {
    container = querySelector('#' + configuration.containerId);
    actions = new Actions();
    graphicStore = new GraphicStore(this);
    shapeSettings = new ShapeSettings(this);
    selectionStore = new SelectionStore(this);
    canvasController = new CanvasController(this);
  }
}
