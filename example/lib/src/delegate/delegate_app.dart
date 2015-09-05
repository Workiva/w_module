library w_module.example.lib.src.delegate.delegate_app;

import 'dart:async';
import 'dart:html' as html;

import 'package:react/react.dart' as react;
import 'package:react/react_client.dart' as react_client;
import 'package:w_module/w_module.dart';

import 'color_module.dart';

main() async {
  // set up a mock delegate data source and event
  List<String> listData = ['red', 'green', 'blue', 'magenta'];
  DispatchKey _dispatchKey = new DispatchKey('testModuleDelegate');
  Event<String> newData = new Event<String>(_dispatchKey);
  void addColorToList(String color) {
    listData.add(color);
    newData(color, _dispatchKey);
  }

  // instantiate the delegate
  ColorDelegate delegate = new ColorDelegate(
      () => listData, () => listData.last, addColorToList, newData);

  // instantiate a module with the delegate and render it
  html.Element container = html.querySelector('#delegate-container');
  react_client.setClientConfiguration();

  ColorModule colorModule = new ColorModule(delegate);
  await colorModule.load();

  react.render(colorModule.components.content(), container);

  // update some data on a timer to verify that delegate changes trigger module updates
  new Timer.periodic(new Duration(seconds: 2), (_) => addColorToList('blue'));
}
