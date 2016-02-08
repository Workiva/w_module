library w_module.example.deferred_transformer.counter_module;

import 'dart:async';

import 'package:react/react.dart' as react;
import 'package:w_module/alpha/annotations.dart';
import 'package:w_module/w_module.dart';

import 'counter_module_abstracts.dart';
import 'pair.dart';

DispatchKey _dispatchKey = new DispatchKey('counterModule');

@DeferrableModule('CounterModule')
class CounterModule extends Module implements CounterModuleDef {
  CounterApi _api;
  CounterComponents _components;
  CounterEvents _events;

  CounterModule({int startingCount}) : this._(startingCount: startingCount);

  CounterModule.autoIncrement({int startingCount})
      : this._(autoIncrement: true, startingCount: startingCount);

  CounterModule._({bool autoIncrement, int startingCount}) {
    _events = new CounterEvents();
    _api = new CounterApi(_events,
        autoIncrement: autoIncrement ?? false, count: startingCount ?? 0);
    _components = new CounterComponents(_api, events);
  }

  @override
  String get name => 'DeferredCounterModule';

  @override
  CounterApi get api => _api;

  @override
  CounterComponents get components => _components;

  @override
  CounterEvents get events => _events;
}

@DeferrableModuleApi('CounterModule')
class CounterApi implements CounterApiDef {
  bool _autoIncrement;
  int _count = 0;
  CounterEvents _events;

  CounterApi(CounterEvents events, {bool autoIncrement: false, int count})
      : _autoIncrement = autoIncrement,
        _count = count,
        _events = events;

  bool get autoIncrement => _autoIncrement;
  int get count => _count;
  List<Pair<DateTime, int>> get history => [];

  Future<Null> increment({int delta}) async {
    _updateCount(_count + (delta ?? 1));
  }

  Future<Null> decrement({int delta}) async {
    _updateCount(_count - (delta ?? 1));
  }

  Future<Null> update(int count) async {
    _updateCount(count);
  }

  doNothing() {}

  void _updateCount(int count) {
    _count = count;
    _events.onCountChange(count, _dispatchKey);
  }
}

class CounterComponents implements CounterComponentsDef, ModuleComponents {
  CounterApi _api;
  CounterEvents _events;
  CounterComponents(this._api, this._events);
  content() => CounterComponent({'api': _api, 'events': _events});
}

@DeferrableModuleEvents('CounterModule')
class CounterEvents implements CounterEventsDef {
  final Event<int> onCountChange = new Event(_dispatchKey);
}

var CounterComponent = react.registerComponent(() => new _CounterComponent());

class _CounterComponent extends react.Component {
  CounterApi get api => props['api'];
  CounterEvents get events => props['events'];

  StreamSubscription countChangeSub;
  Timer autoIncrementTimer;

  componentDidMount(rootNode) {
    countChangeSub = events.onCountChange.listen((_) {
      redraw();
    });

    if (api.autoIncrement) {
      autoIncrementTimer = new Timer.periodic(new Duration(seconds: 1), (_) {
        api.increment();
      });
    }
  }

  componentWillUnmount() {
    autoIncrementTimer?.cancel();
    countChangeSub?.cancel();
  }

  render() {
    var incButton = react.button({'onClick': _inc}, '+');
    var decButton = react.button({'onClick': _dec}, '-');
    return react.div(
        {}, [react.div({}, 'Counter: ${api.count}'), incButton, decButton]);
  }

  _inc(e) {
    api.increment();
  }

  _dec(e) {
    api.decrement();
  }
}
