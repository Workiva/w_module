// Copyright 2017 Workiva Inc.
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

import 'package:platform_detect/platform_detect.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react_dom.dart' as react_dom;
import 'package:react/react_client.dart' as react_client;
import 'package:w_module/w_module.dart' hide Event;
import 'package:opentracing/opentracing.dart';

import 'modules/panel_module.dart';
import 'modules/sample_tracer.dart';

Future<Null> main() async {
  Element container = querySelector('#panel-container');
  react_client.setClientConfiguration();

  final tracer = new SampleTracer();
  initGlobalTracer(tracer);
  assert(globalTracer() == tracer);

  // instantiate the core app module and wait for it to complete loading
  PanelModule panelModule = new PanelModule();
  await panelModule.load();

  // block browser tab / window close if necessary
  window.onBeforeUnload.listen((Event event) {
    if (event is! BeforeUnloadEvent) return;
    BeforeUnloadEvent beforeUnloadEvent = event;

    // can the app be unloaded?
    ShouldUnloadResult res = panelModule.shouldUnload();
    if (!res.shouldUnload) {
      // return the supplied error message to block close
      beforeUnloadEvent.returnValue = res.messagesAsString();
    } else if (browser.isInternetExplorer) {
      // IE interprets a null string as a response and displays an alert to
      // the user. Use the `undefined` value of the JS context instead.
      // https://github.com/dart-lang/sdk/issues/22589
      beforeUnloadEvent.returnValue = js.context['undefined'];
    }
  });

  // render the app into the browser
  react_dom.render(
      ErrorBoundary()(panelModule.components.content()), container);
}
