# w_module
[![Pub](https://img.shields.io/pub/v/w_module.svg)](https://pub.dartlang.org/packages/w_module)
[![Build Status](https://travis-ci.org/Workiva/w_module.svg?branch=master)](https://travis-ci.org/Workiva/w_module)
[![codecov.io](http://codecov.io/github/Workiva/w_module/coverage.svg?branch=master)](http://codecov.io/github/Workiva/w_module?branch=master)
[![documentation](https://img.shields.io/badge/Documentation-w_module-blue.svg)](https://www.dartdocs.org/documentation/w_module/latest/)

> Base module classes with a well defined lifecycle for modular Dart applications.

- [**Overview**](#overview)
- [**Module Structure**](#module-structure)
  - [**API**](#api)
  - [**Events**](#events)
  - [**Components**](#components)
- [**Module Lifecycle**](#module-lifecycle)
  - [**Lifecycle Methods**](#lifecycle-methods)
  - [**Lifecycle Events**](#lifecycle-events)
  - [**Lifecycle Customization**](#lifecycle-customization)
  - [**Module Hierarchies**](#module-hierarchies)
  - [**Disposal**](#disposal)
- [**Examples**](#examples)
- [**Development**](#development)


---

## Overview

![w_module Boundaries Diagram](https://raw.githubusercontent.com/Workiva/w_module/images/images/w_module_boundaries_diagram.png)

`w_module` implements a module encapsulation and lifecycle pattern for Dart that interfaces well with the application
architecture defined in the [w_flux](https://github.com/Workiva/w_flux) library.  `w_module` defines the public interface
for a module and is in no way prescriptive as to how module internals are defined, though the `w_flux` pattern is
recommended.  `w_module` defines how data should flow in and out of a module, how renderable UI is exposed to consumers,
and establishes a common module lifecycle that facilitates dynamic loading / unloading of complex module hierarchies.


---

## Module Structure

A `w_module` `Module` encapsulates a well-scoped logical unit of functionality and exposes a discrete public interface for
consumers.  It extends `LifecycleModule` to ensure that its load / unload processes adhere to a well-defined lifecycle.
The public interface of a `Module` is comprised of `api`, `events`, and `components`:
- The `api` class exposes public methods that can be used to mutate or query module data.
- The `events` class exposes streams that can be listened to for notification of internal module state change.
- The `components` class exposes react-dart compatible UI components that can be used to render module data.

Though the class based `Module` convention is somewhat arbitrary, exposing `api`, `events`, and `components` via
aggregate classes simplifies consumption and improves the discoverability of the `Module`'s public interface.

```dart
// bare bones module definition

DispatchKey sampleDispatchKey = DispatchKey('sampleModule');

class SampleModule extends Module {

  final String name = 'SampleModule';

  SampleApi _api;
  SampleApi get api => _api;

  SampleEvents _events;
  SampleEvents get events => _events;

  SampleComponents _components;
  SampleComponents get components => _components;

  SampleModule() {
    _api = SampleApi();
    _events = SampleEvents(sampleDispatchKey);
    _components = SampleComponents();
  }
}
```

If using `w_module` with `w_flux` internals, `api`, `events`, and `components` should be internally initialized with
access to the module's `actions` and `stores`.

```dart
// module definition with w_flux internals

DispatchKey sampleDispatchKey = DispatchKey('sampleModule');

class SampleModule extends Module {

  final String name = 'SampleModule';

  SampleActions _actions;
  SampleStore _store;

  SampleApi _api;
  SampleApi get api => _api;

  SampleEvents _events;
  SampleEvents get events => _events;

  SampleComponents _components;
  SampleComponents get components => _components;

  SampleModule() {
    _actions = SampleActions();
    _events = SampleEvents();
    _store = SampleStore(_actions, _events, sampleDispatchKey);
    _components = SampleComponents(_actions, _store);
    _api = SampleApi(_actions, _store);
  }
}
```


### API

A `Module`'s `api` member should expose all public methods that a consumer can use to mutate module state (methods) or
query existing module state (getters).  `api` is initially null.  If a module exposes a public `api`, this should be
overridden to provide a class defined specifically for the module.

```dart
// module api definition

class SampleApi {

  SampleApi();

  setSampleValue(String newValue) {
    ...
  }

  String get sampleValue => ...;
}
```

```dart
// module api consumption

sampleModule.api.setSampleValue(...);

String sampleValue = sampleModule.api.sampleValue;
```

If using `w_module` with `w_flux` internals, module mutation methods should usually dispatch existing `actions`
available within the module.  This ensures that the internal unidirectional data flow is maintained, regardless of
the source of the mutation (e.g. external api or internal UI).  Likewise, module methods that expose internal state
should usually use existing getter methods available on stores within the module.

```dart
// module api definition with w_flux internals

class SampleApi {

  SampleActions _actions;
  SampleStore _store;

  SampleApi(this._actions, this._store);

  setSampleValue(String newValue) {
    _actions.setSampleValue(newValue);
  }

  String get sampleValue => _store.sampleValue;
}
```


### Events

A `Module`'s `events` member should expose all public streams that a consumer can listen to for notification of
internal state changes.  `events` is initially null.  If a module exposes public `events`, this should be overridden
to provide a class defined specifically for the module.

A `Module`'s `events` are intended to be 'read-only'.  Though `events` are exposed for listening by external consumers,
they should only be dispatched from within the `Module`.  To enforce this limitation, a dispatch key is required to
instantiate the event stream.  The same dispatch key must subsequently be used to dispatch all events on the stream.
Keeping the dispatch key private in the `Module` internals effectively prevents uncontrolled external dispatch.

```dart
// module events definition

DispatchKey sampleDispatchKey = DispatchKey('sampleModule');

class SampleEvents {
  final Event<String> valueChanged = Event(sampleDispatchKey);
}
```

```dart
// module events dispatch

_events.valueChanged(_sampleValue, sampleDispatchKey);
```

```dart
// module events consumption

sampleModule.events.valueChanged.listen((newValue) {
  ...
});
```

In order to automatically clean up subscriptions if the module is disposed, you can make use of `listenToStream` instead of the built-in `listen`. See [the section on disposal](#disposal) for more details.


```dart

// module events consumption
listenToStream(sampleModule.events.valueChanged, (newValue) {
  ...
});
```

If using `w_module` with `w_flux` internals, `events` should usually be dispatched by internal stores immediately
prior to a corresponding trigger dispatch.  `events` should NOT be dispatched directly by UI components or in
immediate response to actions.  This ensures that the internal unidirectional data flow is maintained and external
`events` represent confirmed internal state changes.

```dart
// module events dispatch with w_flux internals

class SampleStore extends Store {

  String _sampleValue = 'something';

  RandomColorEvents _events;
  DispatchKey _dispatchKey;

  SampleActions _actions;

  SampleStore(SampleActions this._actions, SampleEvents this._events, DispatchKey this._dispatchKey) {
    ...
    _actions.setSampleValue.listen(_setSampleValue);
  }

  _setSampleValue(String newValue) {
    _sampleValue = newValue;
    _events.valueChanged(_sampleValue, _dispatchKey);
    trigger();
  }
}
```

To assist in properly disposing of `Event` instances, `w_module` provides an
`EventsCollection` base class that extends
[`Disposable` from the `w_common` package](https://github.com/Workiva/w_common)
with an additional `manageEvent()` method. Colocating related events in an
`EventsCollection` makes it trivial to close all `Event` instances by disposing
the `EventsCollection` instance.

```dart
final key = DispatchKey('example');

class ExampleEvents extends EventsCollection {
  final Event<String> eventA = Event<String>(key);
  final Event<String> eventB = Event<String>(key);

  ExampleEvents() : super(key) {
    [
      eventA,
      eventB,
    ].forEach(manageEvent);
  }
}

main() async {
  final eventsCollection = EventsCollection();
  await eventsCollection.dispose();
  // All Events on the collection should now be closed.
}
```

### Components

A `Module`'s `components` member should expose all react-dart compatible UI component factories that a consumer can
use to render module data. `components` is initially null.  If a module exposes public `components`, this should be
overridden to provide a class defined specifically for the module.

By convention, the custom `components` class should extend the included `ModuleComponents` class to ensure that the
default UI component is available via the `module.components.content()` method.

```dart
// module components definition

class SampleComponents implements ModuleComponents {

  content() => SampleComponent(...);
}
```

```dart
// module components consumption

react.render(sampleModule.components.content(),
    html.querySelector('#content-container'));
```

If using `w_module` with `w_flux` internals, `components` methods should usually return UI component factories that
have been internally initialized with the proper actions and stores props.  This ensures full functionality of the
`components` without any external exposure of the requisite internal actions and stores.

```dart
// module components definition with w_flux internals

class SampleComponents implements ModuleComponents {

  SampleActions _actions;
  SampleStore _store;

  SampleComponents(this._actions, this._store);

  content() => SampleComponent({'actions': _actions, 'store': _store});
}
```


---

## Module Lifecycle

`w_module` implements a simple `Module` lifecycle that ensures that modules adhere to a predictable loading and
unloading pattern.  Using `Module` as the basis for all modules in an application ensures that this simple pattern
will extrapolate predictably across complex module hierarchies.

Many examples of `Module` lifecycle behavior and manipulation can be found in the
[Multiple Module Panel](https://github.com/Workiva/w_module/tree/master/example/panel) example.

### Lifecycle Methods

`Module` exposes five lifecycle methods that external consumers should use to trigger loading and unloading
behavior. These methods can return an error or exception thrown by their respective lifecycle handler methods.
This allows dependencies on a `Module` to respond to failures that occur within the overridden lifecycle 
behavior.

Method         | Description
-------------- | ---------------------------------
`load`         | Triggers loading of a `Module`.  Internally, this executes the module's `onLoad` method and dispatches the `willLoad` and `didLoad` events.  Returns a future that completes once the module has finished loading.
`suspend`      | Suspends the module and all child modules. While suspended modules should make themselves lightweight and avoid making network requests.
`resume`       | Brings the module and all child modules out of suspension. Upon resuming, modules should go back to business as usual.
`shouldUnload` | Returns the unloadable state of the `Module` and its child modules as a `ShouldUnloadResult`.  Internally, this executes the module's `onShouldUnload` method.
`unload`       | Triggers unloading of a `Module` and all of its child modules.  Internally, this executes the module's `shouldUnload` method, and, if that completes successfully, executes the module's `onUnload` method. If unloading is rejected, this method will complete with an error. The rejected error will not be added to the `didUnload` lifecycle event stream.

![Lifecycle of a LifecycleModule](https://raw.githubusercontent.com/Workiva/w_module/images/images/LifecycleModule_lifecycle_diagram.png)

The graphic above illustrates legal lifecycle state transitions. Any state
transition that is not defined will throw a `StateError`. No-op transitions are
illustrated with blue arrows. Calling the lifecycle method when the module is
already in the given state will result in a logger warning. If a no-op is
performed on a transitioning state the pending transition future is returned.

### Lifecycle Events

`Module` also exposes lifecycle event streams that an external consumer can listen to. If any corresponding lifecycle handler method throws an exception or error it will be added to the corresponding stream. This allows dependencies on a `Module` to provide an `onError` function to handle recovering from a failure within the module implementation.

Event          | Description
-------------- | ---------------------------------
`willLoad`     | Dispatched at the beginning of the module's `load` logic.
`didLoad`      | Dispatched at the end of the module's `load` logic.
`willSuspend`  | Dispatched at the beginning of the module's `suspend` logic.
`didSuspend`   | Dispatched at the end of the module's `suspend` logic.
`willResume`   | Dispatched at the beginning of the module's `resume` logic.
`didResume`    | Dispatched at the end of the module's `resume` logic.
`willUnload`   | Dispatched at the beginning of the module's `unload` logic.
`didUnload`    | Dispatched at the end of the module's `unload` logic.

### Lifecycle Customization

Internally, `Module` contains methods that can be overridden to customize module lifecycle behavior. Any error or exception thrown by these overloaded lifecycle methods will be added to their corresponding lifecycle event stream. This error will be returned to the caller of the corresponding lifecycle method. 

Method           | Description
---------------- | ---------------------------------
`onLoad`         | Executing during the module's `load` logic.  Custom logic for initializing child modules, service access, event listeners, etc. should be implemented here.  Deferred module loading behavior can also be hidden from consumers via this method.
`onSuspend`      | Executed during the module's `suspend` logic. This method should be used to modify module behavior while suspended.
`onResume`       | Executed during the module's `resume` logic. This method should be used to put the module back into its normal mode of operation.
`onShouldUnload` | Executed during the module's `shouldUnload` logic.  Custom logic that blocks module unloading under certain conditions should be implemented here.
`onUnload`       | Executed during the module's `unload` logic.  Custom module clean up logic should be implemented here.  Unfortunately, the nature of web browsers is such that module `unload` logic is not guaranteed to be executed under all conditions (browser or tab close), so mission critical logic should not reside here.

### Module Hierarchies

`Module` also supports hierarchical application of the standard lifecycle through child modules:

Method                | Description
--------------------  | ---------------------------------
`loadChildModule`     | Loads a child module and registers it with the current module for lifecycle management.
`willLoadChildModule` | Dispatched at the beginning of the child module's `load` logic.
`didLoadChildModule`  | Dispatched at the end of the child module's `load` logic.

### Getters

Getter               | Description
-------------------- | ---------------------------------
`childModules`       | An iterable of child modules.
`isLoaded`           | A boolean that indicates whether the module is current loaded.
`isSuspended`        | A boolean that indicates whether the module is currently suspended. This will always be false when the module is not loaded.

### Disposal

`Module` extends [`Disposable` from the `w_common` package](https://github.com/Workiva/w_common)
which provides some additional facilities for memory management. This means that
you can leverage any of the disposable management APIs like `listenToStream()`
or `manageDisposable()` within your `Module`. Additionally, it means that
`Module`s can be disposed via `dispose()`. While this is similar to `unload()`,
there is a key difference:

**`unload()`** will attempt to unload a `Module`, but may fail to complete in
two scenarios:
- if the unload is canceled via `shouldUnload()`
- if the unload fails due to an uncaught exception in `onUnload()`

If the unload succeeds, then disposal will happen implicitly.

**`dispose()`** will attempt to unload the `Module` first (unless it has never
been loaded, in which case it will go straight to disposal), but will force
disposal regardless of the outcome of the unload step.

In most scenarios, consumers should use `unload()` either directly or indirectly
via the other lifecycle management APIs like `loadChildModule()`.

Calling `dispose()` should be reserved for scenarios where you know the `Module`
has not been loaded, but still needs to be disposed, or when you need to force
the disposal of the `Module` regardless of its state and do not care about the
`Module`s ability to prevent its unloading. Unit tests are a likely candidate
for this usage.

![Disposal of a LifecycleModule](https://raw.githubusercontent.com/Workiva/w_module/images/images/LifecycleModule_disposal_diagram.png)

---

## Examples

Simple examples of `w_module` usage can be found in the `example` directory. The example [README](example/README.md)
includes instructions for building / running them.


---

## Development

This project leverages [the dart_dev package](https://pub.dartlang.org/packages/dart_dev)
for most of its tooling needs, including static analysis, code formatting,
running tests, collecting coverage, and serving examples. Check out
[the dart_dev readme](https://github.com/Workiva/dart_dev) for more information.
