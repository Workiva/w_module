part of dartsy.components;

class ResizeHandleComponent extends React.Component {
  static final num halfHandleSize = HANDLE_SIZE / 2;

  Context get _context => props['context'];
  Graphic get _selection => props['selection'];
  String get _coord => props['coord'];

  componentDidMount(Element rootNode) {
    (getDOMNode() as Element)
      ..onMouseDown.listen(_handleMouseDown);
  }

  render() {
    var point = _getPointForCoord(_selection, _coord);
    return React.rect({
      'key': 'handle',
      'x': point.x - halfHandleSize,
      'y': point.y - halfHandleSize,
      'width': HANDLE_SIZE,
      'height': HANDLE_SIZE,
      'fill': HANDLE_COLOR,
      'stroke': HANDLE_COLOR_ALT,
      'strokeWidth': HANDLE_STROKE_WIDTH,
      'style': {
        'cursor': '$_coord-resize'
      }
    });
  }

  void _handleMouseDown(MouseEvent event) {
    _context.actions.resizeHandleMouseDown(new GraphicHandleMouseEvent(_coord, _selection, event));
  }

  Point _getPointForCoord(Graphic graphic, String coord) {
    var boundingBox = graphic.getBoundingBox();
    switch (coord) {
      case Directions.NW:
        return new Point(boundingBox.left, boundingBox.top);
      case Directions.NE:
        return new Point(boundingBox.right, boundingBox.top);
      case Directions.SE:
        return new Point(boundingBox.right, boundingBox.bottom);
      case Directions.SW:
        return new Point(boundingBox.left, boundingBox.bottom);
      default:
        throw new StateError('props["coord"] of "$coord" is unknown.');
    }
  }
}
