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

/// The w_module library implements a module encapsulation and lifecycle
/// pattern for Dart that interfaces well with the application architecture
/// defined in the w_flux library.
///
/// w_module defines how data should flow in and out of a module, how renderable
/// UI is exposed to consumers, and establishes a common module lifecycle that
/// facilitates dynamic loading / unloading of modules.
library w_module;

export 'package:w_module/src/event.dart';
export 'package:w_module/src/events_collection.dart';
export 'package:w_module/src/lifecycle_module.dart'
    hide LifecycleState, maxChildUnloadDuration;
export 'package:w_module/src/module.dart';
export 'package:w_module/src/simple_module.dart';
export 'package:w_module/src/timing_specifiers.dart';
