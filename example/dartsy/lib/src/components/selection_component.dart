part of dartsy.components;

class SelectionComponent extends React.Component {

  Context get _context => props['context'];
  Graphic get _selection => state['selection'];

  componentWillMount() {
    _setSelection();
  }

  componentDidMount(Element root) {
    // TODO - component shouldn't listen to actions.  it should listen to stores...
    // any way to prevent listening to actions from the component?
    _context.actions.selectionChanged.listen(_handleSelectionChanged);
  }

  componentWillUnmount() {
//    _context.actions.selectionChanged.unsubscribe(_handleSelectionChanged);
  }

  render() {
    var selection = _selection;
    if (selection == null) {
      return null;
    }
    var boundingBox = selection.getBoundingBox();
    var outlineComponent = React.rect({
      'key': 'outline',
      'x': boundingBox.left,
      'y': boundingBox.top,
      'width': boundingBox.width,
      'height': boundingBox.height,
      'fill': 'none',
      'stroke': HANDLE_COLOR,
      'strokeWidth': HANDLE_STROKE_WIDTH
    });
    var resizeHandleComponents = _getResizeHandleLocations(selection).map((loc) {
      return resizeHandle({
        'key': loc,
        'context': _context,
        'coord': loc,
        'selection': selection
      });
    }).toList();
    var rotateHandleComponent;
    if (selection is Shape && selection is! Line) {
      rotateHandleComponent = rotateHandle({
        'key': 'rotator',
        'context': _context,
        'selection': selection
      });
    }
    return React.g({
      'transform': _getTransformForGraphic(selection)
    }, [outlineComponent]..addAll(resizeHandleComponents)..add(rotateHandleComponent));
  }

  void _setSelection() {
    setState({'selection': _context.selectionStore.selection});
  }

  void _handleSelectionChanged(_) {
    _setSelection();
  }

  _getResizeHandleLocations(graphic) {
    List handleLocations;
    if (graphic is Line) {
      Line line = graphic;
      var angle = getAngleBetweenPoints(
          new Point(line.x1, line.y1), new Point(line.x2, line.y2));
      if ((0 <= angle && angle < 90) || (180 <= angle && angle < 270)) {
        handleLocations = [Directions.SW, Directions.NE];
      } else {
        handleLocations = [Directions.NW, Directions.SE];
      }
    } else {
      handleLocations = [Directions.NW, Directions.NE, Directions.SE, Directions.SW];
    }
    return handleLocations;
  }
}
