library w_module.example.deferred_transformer.index;

import 'dart:async';
import 'dart:html';

import 'package:react/react.dart' as react;
import 'package:react/react_client.dart';

import 'deferred_counter_module.dart';

Element container = querySelector('#container');
ButtonElement load = querySelector('#load');
ButtonElement loadAlt = querySelector('#load-alt');

void main() {
  setClientConfiguration();

  load.onClick.listen((_) {
    loadAndRender(new DeferredCounterModule());
  });

  loadAlt.onClick.listen((_) {
    loadAndRender(new DeferredCounterModule.autoIncrement());
  });
}

Future loadAndRender(DeferredCounterModule counterModule) async {
  react.render(DeferredCounterModule.loadingComponent, container);

  counterModule.events.onCountChange.listen((c) => print('Count: $c'));
  counterModule.api.update(10);

  await counterModule.load();
  react.render(counterModule.components.content(), container);
}
