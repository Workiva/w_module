library w_module.example.dartsy.module.components.drawing_component;

import 'package:react/react.dart' as react;

var DartsyDrawingComponent = react.registerComponent(() => new _DartsyDrawing());
class _DartsyDrawing extends react.Component {

  render() {
    return react.div({}, ['Dartsy Drawing Component']);
  }

}
