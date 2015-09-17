library w_module.example.panel.modules.deferred_heavyLifter_implementation;

import './deferred_heavyLifter_interface.dart';

class RealLifter implements HeavyLifter {
  HeavyLifterDivision _division;
  HeavyLifterDivision get division => _division;

  RealLifter(HeavyLifterDivision this._division);

  List<String> get competitors {
    if (_division == HeavyLifterDivision.FEATHERWEIGHT) {
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
    } else if (_division == HeavyLifterDivision.WELTERWEIGHT) {
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
    } else if (_division == HeavyLifterDivision.HEAVYWEIGHT) {
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
}
