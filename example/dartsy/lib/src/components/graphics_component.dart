part of dartsy.components;

class GraphicsComponent extends React.Component {

  Context get _context => props['context'];
  List<Graphic> get _graphics => state['graphics'];

  componentWillMount() {
    _setGraphics();
  }

  componentDidMount(Element rootNode) {
    _context.actions.graphicStoreChanged.listen((_) => _setGraphics());
  }

  componentWillUnmount() {
//    _context.actions.graphicStoreChanged.unsubscribe(_setGraphics);
  }

  render() {
    var graphicComponents = _graphics.where((g) => g is Shape).map((g) {
      return shape({
        'key': g.key,
        'context': _context,
        'shape': g
      });
    }).toList();
    return React.g({}, graphicComponents);
  }

  void _setGraphics() {
    setState({'graphics': _context.graphicStore.graphics});
  }
}
