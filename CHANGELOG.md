## [3.0.11](https://github.com/Workiva/w_module/compare/3.0.9...3.0.11)

_February 24, 2026_

- **Maintenance:** Set SDK constraint to '>=2.19.0 <4.0.0'

## [3.0.10](https://github.com/Workiva/w_module/compare/3.0.9...3.0.10)

_February 22, 2026_

- **Bug Fix:** Fixed issues identified from the prior release.
- **Maintenance:** Updated GHA workflows and dependency constraints, and rolled
  React 18 to tests and example apps.

## [3.0.9](https://github.com/Workiva/w_module/compare/3.0.8...3.0.9)

_March 18, 2025_

- **Improvement:** Log a warning and skip unloading a child module if it takes
  too long to unload.

## [3.0.8](https://github.com/Workiva/w_module/compare/3.0.7...3.0.8)

_December 6, 2024_

- **Improvement:** Updated `onResume` typing.
- **Maintenance:** Applied CI/dependency modernization (GHA OSS/workflows,
  mocktail migration, analysis options v2, and SDK/dependency bound updates).

## [3.0.7](https://github.com/Workiva/w_module/compare/3.0.6...3.0.7)

_March 29, 2024_

- **Improvement:** Updated `over_react` dependencies to consume the null-safe
  version.

## [3.0.6](https://github.com/Workiva/w_module/compare/3.0.5...3.0.6)

_March 4, 2024_

- **Bug Fix:** A child module which loads during the unload of the parent
  may cause BadState exceptions.

## [3.0.0](https://github.com/Workiva/w_module/compare/2.0.5...3.0.0)

_August 18, 2023_

- **Improvement:** Updated to null safety

## [2.0.5](https://github.com/Workiva/w_module/compare/2.0.4...2.0.5)

_December 13, 2018_

- **Bug Fix:** Address some memory leak edge cases around child modules:
  - Clear the list of child modules when the parent module is disposed.
  - Use `manageDisposable()` to manage a child module as soon as it is added
    instead of manually disposing each child module during parent module
    disposal.

## [2.0.4](https://github.com/Workiva/w_module/compare/2.0.3...2.0.4)

_November 27, 2018_

- **Improvement:** Dart 2 compatible!

## [2.0.3](https://github.com/Workiva/w_module/compare/2.0.0...2.0.3)

_October 16, 2018_

- **Feature:** Added OpenTracing support to `Module`.

  See [the tracing documentation][tracing] for more info.

## [2.0.0](https://github.com/Workiva/w_module/compare/1.6.2...2.0.0)

_Sep 13, 2018_

[tracing]: https://github.com/Workiva/w_module/blob/master/documentation/tracing.md

- **BREAKING CHANGE:** Remove the `package:w_module/serializable_module.dart`
  entry point, as it depended on `dart:mirrors` which is no longer supported in
  the browser in Dart 2.

  Consequently, the following API members have been removed:

  - `Bridge`
  - `Reflectable`
  - `SerializableBus`
  - `SerializableEvent`
  - `SerializableEvents`
  - `SerializableModule`
