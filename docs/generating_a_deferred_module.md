
# Generate a Deferred Module
Once you've created a Module, you can easily generate a deferred version. From a consumption perspective, the usage is exactly the same. Under the hood, the deferred library loading is hidden within the module's `load()` lifecycle event.

## Tools
You'll need to install the `source_gen` library and create a script to run the code generation.

Update your `pubspec.yaml`:
```yaml
dev_dependencies:
  source_gen: "^0.4.2"
```

Create a `generate.dart` file:
```dart
import 'package:source_gen/source_gen.dart';
import 'package:w_module/code_generation.dart'
    show DeferredModuleGenerator;

List librarySearchPaths = ['lib/'];

void main(List<String> args) {
  build(args, const [
    const DeferredModuleGenerator()
  ], librarySearchPaths: librarySearchPaths).then((msg) {
    print(msg);
  });
}
```

## Example Scenario
Let's assume that you have the following file structure, where `example_module.dart` contains the module `ExampleModule` for which we want to create a deferred version.

```
- lib/
  - src/
    - example_api.dart
    - example_components.dart
    - example_events.dart
    - example_module.dart
  - example.dart
```

**example_api.dart**
```dart
class ExampleApi { /* ... */ }
```

**example_components.dart**
```dart
class ExampleComponents { /* ... */ }
```

**example_events.dart**
```dart
class ExampleEvents { /* ... */ }
```

**example_module.dart**
```dart
import 'package:w_module/w_module.dart';

import 'example_api.dart' show ExampleApi;
import 'example_components.dart' show ExampleComponents;
import 'example_events.dart' show ExampleEvents;

class ExampleModule extends Module {
  ExampleApi get api => new ExampleApi();
  ExampleComponents get components => new ExampleComponents();
  ExampleEvents get events => new ExampleEvents();

  @override
  Future onLoad() { /* ... */ }
}
```

## Create a Home for the Deferred Version

The next step is to create a new file next to the actual module file ( `example_module.dart`) and prefix it with `deferred_` (`deferred_example_module.dart`).

**deferred_example_module.dart**
```dart
/// Decorate this library, telling the `DeferredModule`
/// annotation where the relevant module classes can be found.
/// The module class is required, while the API, events,
/// and components classes are optional.
@DeferredModule(
    #example_module.ExampleModule,
    api: #example_api.ExampleApi,
    components: #example_components.ExampleComponents,
    events: #example_events.ExampleEvents
)
library example.src.deferred_example_module.dart;

/// Import the `DeferredModule` annotation from w_module.
import 'package:w_module/w_module.dart'
    show DeferredModule;

/// Import the real code as deferred libraries.
/// Since we point to them above, the deferred
/// module generation will create the logic
/// necessary for loading them.
import 'example_api.dart' deferred as example_api;
import 'example_components.dart' deferred as example_components;
import 'example_events.dart' deferred as example_events;
import 'example_module.dart' deferred as example_module;
```

## Generate!
Now that our annotation is in place, we need to run the source generation tool. Our deferred module will be generated for us!

```
dart generate.dart
```

## Include the Generated Code
The `source_gen` package places the generated file next to the file that triggered the generation (our `deferred_` file that had the `DeferredModule()` annotation) and uses the `.g.dart` extension. In our example, that would be `deferred_example_module.g.dart`.

The last thing left to do is to include this generated code. In the deferred file, add a `part` declaration to do so.

**deferred_example_module.dart**
```dart
// continued from above..
part 'deferred_example_module.g.dart';
```

## Done!
Your deferred module is ready to use. Export it in your project's main entry point, or where appropriate, and use it just like you would the regular module.