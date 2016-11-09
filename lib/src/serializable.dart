// Copyright 2016 Workiva Inc.
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

library serializable_module.src.serializable;

@MirrorsUsed(metaTargets: 'serializable_module.src.serializable.Reflectable')
import 'dart:mirrors';
import 'dart:async';
import 'dart:html' show window, CustomEvent;
import 'dart:js' show JsObject, context;

import 'package:logging/logging.dart';
import 'package:w_common/w_common.dart' show JsonSerializable;

import 'event.dart';
import 'module.dart';

// Any classes / methods that are going to be reflected must annotate with this
class Reflectable {
  const Reflectable();
}

abstract class Bridge<T> {
  StreamController<Map> _eventController;

  Bridge() {
    _eventController = new StreamController<Map>.broadcast();
  }

  void broadcast(Map dataToSend);
  void handleEvent(T apiCall);

  Stream<Map> get eventReceived => _eventController.stream;
}

// This class is used to communicate across a WKWebView in an iOS app
class WKWebViewBridge extends Bridge<CustomEvent> {
  WKWebViewBridge() {
    window.on['bridge'].listen(handleEvent);
  }

  @override
  void broadcast(Map dataToSend) {
    wkBridge?.callMethod('postMessage', [new JsObject.jsify(dataToSend)]);
  }

  @override
  void handleEvent(CustomEvent apiCall) {
    _eventController.add(apiCall.detail);
  }

  JsObject get wkBridge {
    if (context['webkit'] != null) {
      return context['webkit']['messageHandlers']['bridge'];
    } else {
      return null;
    }
  }
}

class SerializableEvent<T> extends Event<T> {
  SerializableEvent(this._eventKey, DispatchKey dispatchKey)
      : super(dispatchKey);

  String _eventKey;
  String get eventKey => _eventKey;
}

abstract class SerializableEvents {
  List<SerializableEvent> get allEvents => [];
}

abstract class SerializableModule extends Module {
  SerializableModule() {
    _registerWithSerializableBus();
  }

  void _registerWithSerializableBus() {
    SerializableBus.sharedBus.registerModule(this);
  }

  @override
  SerializableEvents get events => null;

  String get serializableKey => null;
}

class SerializableBus {
  SerializableBus() {
    _registeredModules = new Map<String, SerializableModule>();
    _logger = new Logger('Serializable Bus');
  }

  static final SerializableBus _singleton = new SerializableBus();
  static SerializableBus get sharedBus => _singleton;

  Bridge _bridge;
  Logger _logger;
  Map<String, SerializableModule> _registeredModules;

  void reset() {
    _registeredModules = new Map<String, SerializableModule>();
    _bridge = null;
  }

  void registerModule(SerializableModule module) {
    if (module.serializableKey != null) {
      _registerForLifecylceEvents(module);
      _registeredModules[module.serializableKey] = module;
    } else {
      _logger.warning('Unable to serialize module without serializableKey');
    }
  }

  void deregisterModule(SerializableModule module) {
    _registeredModules.remove(module.serializableKey);
  }

  void _registerForAllEvents(SerializableModule module) {
    if (module.events != null) {
      for (var event in module.events.allEvents) {
        if (event is SerializableEvent) {
          event
              .listen((payload) => _sendEvent(module, event.eventKey, payload));
        }
      }
    } else {
      _logger
          .warning('Events not defined for ${module.serializableKey} module');
    }
  }

  void _registerForLifecylceEvents(SerializableModule module) {
    module.willLoad.listen((_) {
      _registerForAllEvents(module);
      _sendEvent(module, 'willLoad', null);
    });
    module.didLoad.listen((_) => _sendEvent(module, 'didLoad', null));
    module.willUnload.listen((_) => _sendEvent(module, 'willUnload', null));
    module.didUnload.listen((_) {
      _sendEvent(module, 'didUnload', null);
      deregisterModule(module);
    });
  }

  void _sendEvent(SerializableModule module, String eventKey, Object data) {
    Map dataToSend = new Map();
    dataToSend['module'] = module.serializableKey;
    dataToSend['event'] = eventKey;

    if (data is JsonSerializable) {
      data = (data as JsonSerializable).toJson();
    }

    dataToSend['data'] = data;

    _bridge?.broadcast(dataToSend);
  }

  void _handleApiCall(Map apiCall) {
    String module = apiCall['module'];
    String method = apiCall['method'];
    Object data = apiCall["data"];

    SerializableModule targetModule = _registeredModules[module];

    _deserializeAndCall(targetModule, method, data);
  }

  void _deserializeAndCall(
      SerializableModule module, String method, List data) {
    InstanceMirror apiMirror = reflect(module.api);
    ClassMirror classMirror = apiMirror.type;
    MethodMirror apiMethodMirror = classMirror.declarations[new Symbol(method)];

    if (apiMethodMirror == null) {
      _logger.warning(
          'Method $method does not exist on ${module.serializableKey}\' module\'s API');
      return;
    }

    // Check here that the position args in data match the expected params of the method being called
    if (data is List && apiMethodMirror.parameters.length == data.length) {
      for (var i = 0; i < apiMethodMirror.parameters.length; i++) {
        var param = apiMethodMirror.parameters[i];

        // If the type data being passed to this param is not equal to the expected type
        // try to serialize it into an Dart class
        if (param.type.reflectedType != data[i].runtimeType && data[i] is Map) {
          ClassMirror paramClassMirror = reflectClass(param.type.reflectedType);

          // Paramter type must implement fromJson model that takes a Map
          try {
            var instance = paramClassMirror
                .newInstance(new Symbol('fromJson'), [data[i]]).reflectee;
            data[i] = instance;
          } on NoSuchMethodError {
            _logger.warning(
                '${paramClassMirror.simpleName.toString()} does not implement fromJson named constructor');
            return;
          }
        } else {
          _logger.warning('Incompatiable type for deserialization');
          return;
        }
      }

      if (apiMirror != null) {
        apiMirror.invoke(new Symbol(method), data);
      }
    } else {
      _logger.warning(
          'Unable to call api method $method in $module w_module, mismatched params');
    }
  }

  Map<String, SerializableModule> get registeredModules => _registeredModules;

  set bridge(Bridge bridge) {
    _bridge = bridge;
    _bridge.eventReceived.listen(_handleApiCall);
  }
}
