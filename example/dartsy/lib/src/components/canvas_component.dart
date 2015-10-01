part of dartsy.components;

class CanvasComponent extends React.Component {

  Context get _context => props['context'];

  componentDidMount(Element rootNode) {
    (getDOMNode() as Element)
      ..onMouseDown.listen(_handleMouseDown)
      ..onMouseMove.listen(_handleMouseMove)
      ..onMouseUp.listen(_handleMouseUp)
    ;
  }

  render() {
    // Get all the graphics to render.
    var graphicsComponent = graphics({
      'key': 'graphics',
      'context': _context
    });
    // Add controls around active elements.
    var selectionComponent = selection({
      'key': 'selection',
      'context': _context
    });
    return React.svg({
      'className': 'drawing-canvas',
      'width': '100%',
      'height': '100%',
      'style': {
        'position': 'absolute'
      }
    }, [graphicsComponent, selectionComponent]);
  }

  void _handleMouseDown(MouseEvent event) {
    _context.actions.canvasMouseDown(event);
  }

  void _handleMouseMove(MouseEvent event) {
    _context.actions.canvasMouseMove(event);
  }

  void _handleMouseUp(MouseEvent event) {
    _context.actions.canvasMouseUp(event);
  }
}
