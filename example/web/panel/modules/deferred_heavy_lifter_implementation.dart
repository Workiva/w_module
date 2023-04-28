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

library w_module.example.panel.modules.deferred_heavy_lifter_implementation;

import './deferred_heavy_lifter_interface.dart';

class RealLifter implements HeavyLifter {
  HeavyLifterDivision _division;

  RealLifter(this._division);

  @override
  List<String> get competitors {
    if (_division == HeavyLifterDivision.featherweight) {
      return [
        'SpongeBob SquarePants',
        'Patrick Star',
        'Gary Wilson Jr the Snail',
        'Sandy Cheeks',
        'Squidward Tentacles',
        'Eugene Krabs',
        'Sheldon Plankton',
        'Karen',
        'Mrs. Puff',
        'Pearl Krabs',
        'Mermaid Man',
        'Barnacle Boy',
        'Larry the Lobster',
        'The Flying Dutchman',
        'Patchy the Pirate',
        'Potty the Parrot',
        'Officer Nancy',
        'Purple Doctorfish',
        'Elaine',
        'Perch Perkins',
        'Harold SquarePants',
        'Squilliam Fancyson',
        'Mrs. Betsy Krabs',
        'Man Ray',
        'Old Man Jenkins',
        'King Neptune',
        'Bubble Buddy',
        'DoodleBob'
      ];
    } else if (_division == HeavyLifterDivision.welterweight) {
      return [
        'Philip J. Fry',
        'Turanga Leela',
        'Bender Bending Rodriguez',
        'Amy Wong',
        'Hermes Conrad',
        'Professor Hubert J. Farnsworth',
        'Doctor John Zoidberg',
        'Lord Nibbler',
        'Zapp Brannigan',
        'Kif Kroker',
        'Mom',
        'Headless Body of Agnew',
        'Boxy',
        'Brain Slugs',
        'Brain Spawn',
        'Calculon',
        'The Crushinator',
        'Father Changstein-El-Gamal',
        'Chanukah Zombie',
        'Clamps',
        'Dwight Conrad',
        'LaBarbara Conrad',
        'Donbot',
        'Elzar',
        'Cubert Farnsworth',
        'Flexo'
      ];
    } else if (_division == HeavyLifterDivision.heavyweight) {
      return [
        'Apollo Creed',
        'Rocky Balboa',
        'Big Chuck Smith',
        'Big Dipper',
        'Big Yank Ball',
        'Billy Snow',
        'Bob Cray',
        'Buddy Shaw',
        'Burt Judge',
        'Dipper Brown',
        'Ernie Roman',
        'Ivan Drago',
        'Jack Reid',
        'James "Clubber" Lang',
        'Joe Chan',
        'Joe Czak',
        'Jose Mendoza',
        'Kofi Langton',
        'Mac Lee Green',
        'Mason Dixon',
        'Mickey Goldmill',
        'Randy Tate',
        'Spider Rico',
        'Tim Simms',
        'Tommy Gunn',
        'Union Cane',
        'Vito Soto',
        'Wolfgang Peltzer'
      ];
    }
    return [];
  }

  @override
  HeavyLifterDivision get division => _division;
}
