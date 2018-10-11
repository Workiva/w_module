# Tracing with w_module

This library supports [OpenTracing][opentracingio] using [opentracing_dart][opentracingdart]. Your application will need to provide a `Tracer` and initialize it with `initGlobalTracer` to opt in to this feature.


To get the traces provided by this library, your module must provide a definition for the `name` getter. This can simply be the name of the class. For example:

```dart
class SomeModule extends Module {
  @override
  final String name = 'SomeModule';
  
  // ... the of the module's implementation
}
```

Spans will be in the form of:

```
$name.$operationName
```

## Types Of Provided Traces

### Tracing Lifecycle Methods

We automically trace each of its lifecycle methods:

- Load
- Unload
- Suspend
- Resume

In addition, any spans created by child modules (loaded with `loadChildModule`) will have a `followsFrom` reference to the parent's span of the respective method to complete the story of the trace.

If you wish to create other `childOf` or `followsFrom` spans on your module's lifecycle spans, you can simply request the `activeSpan`:

```dart
  @override
  Future<Null> onLoad() {
    // ... some loading logic

    final span = globalTracer().startSpan(
      operationName,
      childOf: activeSpan.context, // see this line
    );

    // ... more loading logic
    span.finish()
  }
```

Note that `activeSpan` will be null at times when the module is not in the middle of a lifecycle transition.

### Additional Load Time Granularity

Sometimes, lifecycle methods such as `load` will complete before the module is semantically "loaded". For example, you may begin asynchronously fetching data for your module and then return from `onLoad` to keep from blocking the main thread.

In cases like these, use `specifyStartupTiming`:

```
  Future<Null> onLoad() {
    // ... kick off async loadData logic

    listenToStream(_events.didLoadData.take(1),
        (_) => specifyStartupTiming(StartupTimingType.firstUseful));
  }
```

This will create a span starting from the same time as `load()` and ending at the moment the method was called. This library will handle the `operationName` and the `followsFrom` reference to the module's `load` span, but tags and references can be passed into this method just like with any other span in optional parameters.

[opentracingio]: https://opentracing.io/
[opentracingdart]: https://github.com/Workiva/opentracing_dart/