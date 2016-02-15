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

import 'dart:async';
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
//  PanelModule panelModule = new PanelModule();
//  bool panelModuleLoaded = false;

  // block browser tab / window close if necessary
//  window.onBeforeUnload.listen((BeforeUnloadEvent event) {
//    // can the app be unloaded?
//    ShouldUnloadResult res = panelModule.shouldUnload();
//    if (!res.shouldUnload) {
//      // return the supplied error message to block close
//      event.returnValue = res.messagesAsString();
//    } else if (browser.isIe) {
//      // IE interprets a null string as a response and displays an alert to
//      // the user. Use the `undefined` value of the JS context instead.
//      // https://github.com/dart-lang/sdk/issues/22589
//      event.returnValue = js.context['undefined'];
//    }
//  });

  // HACK - how can we render more implicitly?
  PanelModule panelModule;

  // initialize the router
  Router router = new Router(useFragment: true);
//  router.addModuleRoute(
//      name: 'panel',
//      path: '/',
//      defaultRoute: true,
//      moduleFactory: () {
//        panelModule = new PanelModule();
//        return panelModule;
//      },
//      enter: (_) {
//        react.render(panelModule.components.content(), container);
//      });

  // simple instantiation
  router.addRoute(
      name: 'panel',
      path: '/',
      defaultRoute: true,
      preEnter: (RoutePreEnterEvent e) {
        Completer<bool> completer = new Completer();
        panelModule = new PanelModule();
        panelModule.load().then((_) {
          panelModule.registerRoutes(router);
          completer.complete(true);
        });
        e.allowEnter(completer.future);
      },
      enter: (_) {
        react.render(panelModule.components.content(), container);
      });

  // manually add root level component for rendering
//  router.root.addRoute(
//      name: 'root',
//      path: '/',
//      defaultRoute: true,
//      preEnter: (RoutePreEnterEvent e) {
//        print('root pre-enter');
//
//        if (!panelModuleLoaded) {
//          // load the panel, hook up routing, and render
//          Completer<bool> completer = new Completer();
//          panelModule.load().then((_) {
//            panelModuleLoaded = true;
//            // set up routes
//            panelModule.registerRoutes(router);
//            // render content
//            react.render(panelModule.components.content(), container);
//            // complete the future
//            completer.complete(true);
//          });
//
//          // complete the preEnter callback
//          e.allowEnter(completer.future);
//        }
//      },
//      preLeave: (RoutePreLeaveEvent e) {
//        print('root pre-leave');
//
//        // prevent route changes based on module shouldUnload
//        // TODO - may not actually make sense to use this on the root module
//        // (the window listener makes more sense for the root)
//        ShouldUnloadResult res = panelModule.shouldUnload();
//        e.allowLeave(new Future.value(res.shouldUnload));
//      });
  router.listen();
}
