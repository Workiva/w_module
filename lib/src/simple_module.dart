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

library w_module.src.simple_module;

/// A [SimpleModule] encapsulates a well-scoped logical unit of functionality and
/// exposes a discrete public interface for consumers.
///
/// The public interface of a [SimpleModule] is comprised of [api], [events],
/// and [components]:
/// - The [api] class exposes public methods that can be used to mutate or query
///   module data.
/// - The [events] class exposes streams that can be listened to for
///   notification of internal module state change.
/// - The [components] class exposes react-dart compatible UI components that
///   can be used to render module data.
abstract class SimpleModule {
  /// The [api] object should contain all public methods that a consumer can use
  /// to mutate module state (methods) or query existing module state (getters).
  ///
  /// [api] is initially null.  If a module exposes a public [api], this should
  /// be overridden to provide a class defined specifically for the module.
  ///
  /// If using with w_flux internals, module mutation methods should usually
  /// dispatch existing actions available within the module.  This ensures
  /// that the internal unidirectional data flow is maintained, regardless of
  /// the source of the mutation (e.g. external api or internal UI).  Likewise,
  /// module methods that expose internal state should usually use existing
  /// getter methods available on stores within the module.
  Object? get api => null;

  /// The [components] object should contain all react-dart compatible UI
  /// component factory methods that a consumer can use to render module data.
  ///
  /// [components] is initially null.  If a module exposes public [components],
  /// this should be overridden to provide a class defined specifically for the
  /// module.  By convention, the custom [components] class should extend
  /// [ModuleComponents] to ensure that the default UI component is available
  /// via the module.components.content() method.
  ///
  /// If using with w_flux internals, [components] methods should usually return
  /// UI component factories that have been internally initialized with the
  /// proper actions and stores props.  This ensures full functionality of the
  /// [components] without any external exposure of the requisite internal
  /// actions and stores.
  ModuleComponents? get components => null;

  /// The [events] object should contain all public streams that a consumer can
  /// listen to for notification of internal module state change.
  ///
  /// [events] is initially null.  If a module exposes public [events], this
  /// should be overridden to provide a class defined specifically for the
  /// module.
  ///
  /// If using with w_flux internals, [events] should usually be dispatched by
  /// internal stores immediately prior to a corresponding trigger dispatch.
  /// [events] should NOT be dispatched directly by UI components or in
  /// immediate response to actions.  This ensures that the internal
  /// unidirectional data flow is maintained and external [events] represent
  /// confirmed internal state changes.
  Object? get events => null;
}

/// Standard [ModuleComponents] class. If a module implements a custom class
/// for its components, it should extend [ModuleComponents].
abstract class ModuleComponents {
  /// The default UI component
  Object? content() => null;
}
