library w_module.example.lib.src.delegate.color_module;

import 'dart:math';

import 'package:w_flux/w_flux.dart';
import 'package:react/react.dart' as react;
import 'package:web_skin_react/web_skin_react.dart' as WSR;
import 'package:w_module/w_module.dart';

class ColorDelegate {
  Function _getColorList;
  Function _getCurrentColor;
  Function _addColor;

  List<String> get colorList => _getColorList();
  String get currentColor => _getCurrentColor();
  void addColor(String color) => _addColor(color);

  Event colorChanged;

  ColorDelegate(
      List<String> this._getColorList(),
      String this._getCurrentColor(),
      void this._addColor(String color),
      Event this.colorChanged);
}

class ColorModule extends Module {
  final String name = 'ColorModule';

  ColorActions _actions;
  ColorStore _stores;

  ColorComponents _components;
  ColorComponents get components => _components;

  ColorModule(ColorDelegate delegate) {
    _actions = new ColorActions();
    _stores = new ColorStore(_actions, delegate);
    _components = new ColorComponents(_actions, _stores);
  }
}

class ColorComponents implements ModuleComponents {
  ColorActions _actions;
  ColorStore _stores;

  ColorComponents(this._actions, this._stores);

  content() => MyColorComponent({'actions': _actions, 'store': _stores});
}

class ColorActions {
  final Action changeBackgroundColor = new Action();
}

class ColorStore extends Store {
  /// Public data
  List<String> get colorList => _delegate.colorList;
  String get currentColor => _delegate.currentColor;

  /// Internals
  ColorActions _actions;
  ColorDelegate _delegate;

  ColorStore(ColorActions this._actions, ColorDelegate this._delegate) {
    _actions.changeBackgroundColor.listen(_changeBackgroundColor);
    _delegate.colorChanged.listen((_) => trigger());
  }

  _changeBackgroundColor(_) {
    // generate a random hex color string
    String newColor =
        '#' + (new Random().nextDouble() * 16777215).floor().toRadixString(16);
    _delegate.addColor(newColor);
  }
}

var MyColorComponent = react.registerComponent(() => new _MyColorComponent());

class _MyColorComponent extends FluxComponent<ColorActions, ColorStore> {
  render() {
    var colorList = [];
    store.colorList
        .forEach((color) => colorList.add(WSR.ListGroupItem({}, color)));

    return react.div({
      'style': {
        'padding': '50px',
        'backgroundColor': store.currentColor,
        'color': 'white'
      }
    }, [
      'This module uses a flux pattern to change its background color.',
      WSR.Input({
        'type': 'submit',
        'value': 'Random Background Color',
        'onClick': actions.changeBackgroundColor
      }),
      WSR.ListGroup({}, colorList)
    ]);
  }
}
