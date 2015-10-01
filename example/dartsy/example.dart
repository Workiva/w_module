import 'dart:html';

import 'package:react/react.dart' as react;
import 'package:react/react_client.dart' as reactClient;

import './module/module.dart';

void main() {

  reactClient.setClientConfiguration();

  // initialize the Dartsy module and render all the available components
  DartsyModule newDartsy = new DartsyModule();
  react.render(newDartsy.components.content(), querySelector('#example-drawing'));
  react.render(newDartsy.components.toolbar(), querySelector('#example-toolbar'));
  react.render(newDartsy.components.toolpanel(), querySelector('#example-toolpanel'));

}
