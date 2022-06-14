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

@TestOn('vm || browser')
import 'package:test/test.dart';
import 'package:w_module/w_module.dart';

class TestModule extends Module {
  @override
  final String name = 'TestModule';
}

void main() {
  group('Module', () {
    TestModule module;

    setUp(() {
      module = TestModule();
    });

    test('should return null from api getter by default', () {
      expect(module.api, isNull);
    });

    test('should return null from components getter by default', () {
      expect(module.components, isNull);
    });

    test('should return null from events getter by default', () {
      expect(module.events, isNull);
    });
  });
}
