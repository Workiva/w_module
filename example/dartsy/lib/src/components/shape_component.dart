part of dartsy.components;

class ShapeComponent extends React.Component {

  Context get _context => props['context'];
  Shape get _shape => props['shape'];

  componentDidMount(Element rootNode) {
    _context.actions.graphicChanged.listen(_handleGraphicChanged);
    (getDOMNode() as Element)
      ..onMouseDown.listen(_handleMouseDown);
  }

  componentWillUnmount() {
//    _context.actions.graphicChanged.unsubscribe(_handleGraphicChanged);
  }

  render() {
    Shape shape = _shape;
    var baseProps = {
      'transform': _getTransformForGraphic(shape),
      'fill': shape.fill,
      'fillOpacity': shape.fillOpacity,
      'stroke': shape.stroke,
      'strokeWidth': shape.strokeWidth,
      'strokeOpacity': shape.strokeOpacity,
      'strokeLinecap': shape.strokeLinecap,
      'strokeDasharray': shape.strokeDashArray == null ?
          null : shape.strokeDashArray.join(' '),
      'style': {
        'cursor': shape.active ? 'move' : null
      }
    };
    // Create the proper SVG element for the graphic.
    var shapeComponent;
    if (shape is Rect) {
      Rect rect = shape;
      shapeComponent = React.rect({
        'x': rect.left,
        'y': rect.top,
        'width': rect.width,
        'height': rect.height,
        'rx': rect.cornerRadiusX,
        'ry': rect.cornerRadiusY
      }..addAll(baseProps));
    }
    else if (shape is Ellipse) {
      Ellipse ellipse = shape;
      shapeComponent = React.ellipse({
        'cx': ellipse.centerX,
        'cy': ellipse.centerY,
        'rx': ellipse.radiusX,
        'ry': ellipse.radiusY
      }..addAll(baseProps));
    }
    else if (shape is Line) {
      Line line = shape;
      shapeComponent = React.line({
        'x1': line.x1,
        'y1': line.y1,
        'x2': line.x2,
        'y2': line.y2
      }..addAll(baseProps));
    }
    return shapeComponent;
  }

  void _handleGraphicChanged(Graphic graphic) {
    if (graphic == _shape) {
      redraw();
    }
  }

  void _handleMouseDown(MouseEvent event) {
    _context.actions.graphicMouseDown(new GraphicMouseEvent(_shape, event));
  }
}
