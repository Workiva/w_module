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

import 'dart:async';
@MirrorsUsed(metaTargets: 'serializable_module.src.serializable.Reflectable')
import 'dart:mirrors';

import 'package:logging/logging.dart';
import 'package:w_common/disposable.dart' show Disposable;
import 'package:w_common/json_serializable.dart' show JsonSerializable;

import 'package:w_module/src/event.dart';
import 'package:w_module/src/module.dart';

// Any classes / methods that are going to be reflected must annotate with this
class Reflectable {
  const Reflectable();
}

abstract class Bridge<T> extends Object with Disposable {
  final Stream<Map> apiCallReceived;
  Bridge(this.apiCallReceived);
  void broadcastSerializedEvent(Map event);
  void handleSerializedApiCall(T apiCall);

  @override
  void manageStreamSubscription(StreamSubscription subscription) {
    super.manageStreamSubscription(subscription);
  }
}

class SerializableEvent<T> extends Event<T> {
  final String eventKey;

  SerializableEvent(this.eventKey, DispatchKey dispatchKey)
      : super(dispatchKey);
}

abstract class SerializableEvents {
  List<SerializableEvent> get allEvents;
}

abstract class SerializableModule extends Module {
  SerializableModule() {
    SerializableBus.sharedBus.registerModule(this);
  }

  @override
  SerializableEvents get events => null;

  String get serializableKey => null;
}

class _ModuleRegistration extends Object with Disposable {
  final SerializableModule module;

  _ModuleRegistration(this.module);

  @override
  void manageStreamSubscription(StreamSubscription subscription) {
    super.manageStreamSubscription(subscription);
  }
}

class SerializableBus {
  static final SerializableBus sharedBus = new SerializableBus();

  Bridge _bridge;
  final Logger _logger = new Logger('Serializable Bus');
  Map<String, _ModuleRegistration> _moduleRegistrations =
      <String, _ModuleRegistration>{};

  Bridge get bridge => _bridge;
  set bridge(Bridge bridge) {
    _bridge = bridge;
    _bridge.manageStreamSubscription(
        bridge.apiCallReceived.listen(_handleApiCall));
  }

  Map<String, SerializableModule> get registeredModules =>
      new Map.fromIterable(_moduleRegistrations.keys,
          value: (key) => _moduleRegistrations[key].module);

  void reset() {
    _moduleRegistrations.clear();
    _bridge.dispose();
    _bridge = null;
  }

  void deregisterModule(SerializableModule module) {
    if (module.serializableKey == null) return;
    if (_moduleRegistrations.containsKey(module.serializableKey)) {
      _moduleRegistrations[module.serializableKey].dispose();
      _moduleRegistrations.remove(module.serializableKey);
    }
  }

  void registerModule(SerializableModule module) {
    if (module.serializableKey != null) {
      final registration = new _ModuleRegistration(module);
      _registerForLifecycleEvents(registration);
      _moduleRegistrations[module.serializableKey] = registration;
    } else {
      _logger.warning('Unable to serialize module without serializableKey');
    }
  }

  void _handleApiCall(Map apiCall) {
    String module = apiCall['module'];
    String method = apiCall['method'];
    Object data = apiCall['data'];

    SerializableModule targetModule = _moduleRegistrations[module].module;

    if (targetModule != null && data is List) {
      _deserializeAndCall(targetModule, method, data);
    }
  }

  void _deserializeAndCall(
      SerializableModule module, String method, List data) {
    InstanceMirror apiMirror = reflect(module.api);

    if (apiMirror == null) {
      _logger.warning(
          'Unable to create mirror on api for ${module.serializableKey}');
      return;
    }

    ClassMirror classMirror = apiMirror.type;
    MethodMirror apiMethodMirror = classMirror.declarations[new Symbol(method)];

    if (apiMethodMirror == null) {
      _logger.warning(
          'Method $method does not exist on ${module.serializableKey}\' module\'s API');
      return;
    }

    // Check here that the position args in data match the expected params of the method being called
    if (apiMethodMirror.parameters.length != data.length) {
      _logger.warning(
          'Unable to call api method $method in ${module.serializableKey} w_module, mismatched params');
      return;
    }

    for (var i = 0; i < apiMethodMirror.parameters.length; i++) {
      var param = apiMethodMirror.parameters[i];

      if (data[i] is Map && param.type.reflectedType != Map) {
        ClassMirror paramClassMirror = reflectClass(param.type.reflectedType);

        // Paramter type must implement fromJson name constructor that takes a Map
        try {
          var instance = paramClassMirror
              .newInstance(new Symbol('fromJson'), [data[i]]).reflectee;
          data[i] = instance;
        } on NoSuchMethodError {
          _logger.warning(
              '${paramClassMirror.simpleName.toString()} does not implement fromJson named constructor');
          return;
        }
      }
    }

    try {
      apiMirror.invoke(new Symbol(method), data);
    } catch (e) {
      _logger.severe(
          'Unable to call $method on ${module.serializableKey} w_module, ${e.toString()}');
    }
  }

  void _registerForAllEvents(_ModuleRegistration registration) {
    if (registration.module.events != null) {
      for (var event in registration.module.events.allEvents) {
        if (event is SerializableEvent) {
          registration.manageStreamSubscription(event.listen((payload) =>
              _sendEvent(registration.module, event.eventKey, payload)));
        }
      }
    } else {
      _logger.info(
          'Events not defined for ${registration.module.serializableKey} module');
    }
  }

  void _registerForLifecycleEvents(_ModuleRegistration registration) {
    registration
        .manageStreamSubscription(registration.module.willLoad.listen((_) {
      _registerForAllEvents(registration);
      _sendEvent(registration.module, 'willLoad', null);
    }));
    registration.manageStreamSubscription(registration.module.didLoad
        .listen((_) => _sendEvent(registration.module, 'didLoad', null)));
    registration.manageStreamSubscription(registration.module.willUnload
        .listen((_) => _sendEvent(registration.module, 'willUnload', null)));
    registration
        .manageStreamSubscription(registration.module.didUnload.listen((_) {
      _sendEvent(registration.module, 'didUnload', null);
      deregisterModule(registration.module);
    }));
  }

  void _sendEvent(SerializableModule module, String eventKey, Object data) {
    Map event = <String, dynamic>{};
    event['module'] = module.serializableKey;
    event['event'] = eventKey;

    if (data is JsonSerializable) {
      data = (data as JsonSerializable).toJson();
    }

    event['data'] = data;

    _bridge?.broadcastSerializedEvent(event);
  }
}
