part of dartsy.components;

class RotateHandleComponent extends React.Component {
  static const num ballOffset = 20;

  Context get _context => props['context'];
  Graphic get _selection => props['selection'];

  componentDidMount(Element rootNode) {
    (getDOMNode() as Element)
      ..onMouseDown.listen(_handleMouseDown);
  }

  render() {
    var boundingBox = _selection.getBoundingBox();
    var x = boundingBox.left + boundingBox.width / 2;
    var y = boundingBox.top;
    var stem = React.line({
      'key': 'stem',
      'x1': x,
      'y1': y,
      'x2': x,
      'y2': y - ballOffset,
      'stroke': HANDLE_COLOR,
      'strokeWidth': HANDLE_STROKE_WIDTH
    });
    var ball = React.circle({
      'key': 'ball',
      'cx': x,
      'cy': y - ballOffset,
      'r': HANDLE_SIZE / 2,
      'fill': HANDLE_COLOR,
      'stroke': HANDLE_COLOR_ALT,
      'strokeWidth': HANDLE_STROKE_WIDTH,
      'style': {
        'cursor': 'crosshair'
      }
    });
    return React.g({}, [stem, ball]);
  }

  void _handleMouseDown(MouseEvent event) {
    _context.actions.rotateHandleMouseDown(new GraphicMouseEvent(_selection, event));
  }
}
