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

import 'package:meta/meta.dart';
import 'package:w_common/disposable.dart';
import 'package:w_module/src/dispatch_key.dart';
import 'package:w_module/src/request.dart';

/// A base class for a collection of [Request] instances that are all tied to the
/// same [DispatchKey].
///
/// Use this class to colocate related [Request] instances and to make disposal of
/// these [Request]s easier.
///
///     final key = new DispatchKey('example');
///
///     class ExampleRequests extends RequestsCollection {
///       final Request<String> requestA = new Request<String>(key);
///       final Request<String> requestB = new Request<String>(key);
///
///       ExampleRequests() : super(key) {
///         [
///           requestA,
///           requestB,
///         ].forEach(manageRequest);
///       }
///     }
class RequestsCollection extends Disposable {
  @override
  String get disposableTypeName => 'RequestsCollection';

  /// The key that every [Request] instance included as a part of this
  /// [RequestsCollection] should be tied to.
  ///
  /// This allows [manageRequest] to close the aforementioned [Request]s.
  final DispatchKey _key;

  RequestsCollection(DispatchKey key) : _key = key;

  /// Registers an [Request] to be closed when this [RequestsCollection] is
  /// disposed.
  @mustCallSuper
  @protected
  void manageRequest(Request request) {
    // TODO do something
  }
}
