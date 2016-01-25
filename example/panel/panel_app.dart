// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library w_module.example.panel;

import 'dart:html';
import 'dart:js' as js;

import 'package:browser_detect/browser_detect.dart';
import 'package:react/react.dart' as react;
import 'package:react/react_client.dart' as react_client;
import 'package:w_module/w_module.dart';
import 'package:w_router/w_router.dart';

import 'modules/panel_module.dart';

main() async {
  Element container = querySelector('#panel-container');
  react_client.setClientConfiguration();

  // instantiate the core app module and wait for it to complete loading
  PanelModule panelModule = new PanelModule();
  await panelModule.load();

  // block browser tab / window close if necessary
  window.onBeforeUnload.listen((BeforeUnloadEvent event) {
    // can the app be unloaded?
    ShouldUnloadResult res = panelModule.shouldUnload();
    if (!res.shouldUnload) {
      // return the supplied error message to block close
      event.returnValue = res.messagesAsString();
    } else if (browser.isIe) {
      // IE interprets a null string as a response and displays an alert to
      // the user. Use the `undefined` value of the JS context instead.
      // https://github.com/dart-lang/sdk/issues/22589
      event.returnValue = js.context['undefined'];
    }
  });

  // initialize the router
  Router router = new Router(useFragment: true);
  panelModule.registerRoutes(router);
  router.listen();

  // render the app into the browser
  react.render(panelModule.components.content(), container);
}
