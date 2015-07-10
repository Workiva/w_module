library w_module.example.panel.deferred_heavyLifter_implementation;

import './deferred_heavyLifter_interface.dart';

class RealLifter implements HeavyLifter {

  HeavyLifterDivision _division;
  HeavyLifterDivision get division => _division;

  RealLifter(HeavyLifterDivision this._division);

  List<String> get competitors {
    // TODO - fill this with more data
    if (_division == HeavyLifterDivision.FEATHERWEIGHT) {
      return [
        'SpongeBob',
        'Patrick'
      ];
    } else if (_division == HeavyLifterDivision.FEATHERWEIGHT) {
      return [
        'Fry',
        'Leela'
      ];
    } else if (_division == HeavyLifterDivision.HEAVYWEIGHT) {
      return [
        'Rocky',
        'Drago'
      ];
    }
    return [];
  }

}
