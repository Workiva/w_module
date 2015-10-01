library dartsy.components;

import 'dart:html';
import 'package:react/react.dart' as React;
import 'constants.dart';
import 'context.dart';
import 'graphics.dart';
import 'utils.dart';

part 'components/canvas_component.dart';
part 'components/graphics_component.dart';
part 'components/resize_handle_component.dart';
part 'components/rotate_handle_component.dart';
part 'components/selection_component.dart';
part 'components/shape_component.dart';
part 'components/utils.dart';

var canvas = React.registerComponent(() => new CanvasComponent());
var graphics = React.registerComponent(() => new GraphicsComponent());
var resizeHandle = React.registerComponent(() => new ResizeHandleComponent());
var rotateHandle = React.registerComponent(() => new RotateHandleComponent());
var selection = React.registerComponent(() => new SelectionComponent());
var shape = React.registerComponent(() => new ShapeComponent());
