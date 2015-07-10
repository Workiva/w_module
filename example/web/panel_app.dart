library w_module.example.app.panel_app;

import 'dart:html';

import 'package:react/react.dart' as react;
import 'package:react/react_client.dart' as react_client;
import 'package:w_module/w_module.dart';

import '../lib/src/panel/panel_module.dart';


main() async {

  Element container = querySelector('#panel-container');
  react_client.setClientConfiguration();

  // instantiate the core app module and wait for it to complete loading
  PanelModule panelModule = new PanelModule();
  await panelModule.load();

  // block browser tab / window close if necessary
  window.onBeforeUnload.listen((event) {

    // can the app be unloaded?
    ShouldUnloadResult res = panelModule.shouldUnload();
    if (!res.shouldUnload) {
      // return the supplied error message to block close
      return res.messagesAsString();
    }

  });

  // render the app into the browser
  react.render(panelModule.buildComponent(), container);

}
