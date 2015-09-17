library w_module.example.panel.modules.deferred_heavyLifter_interface;

enum HeavyLifterDivision { FEATHERWEIGHT, WELTERWEIGHT, HEAVYWEIGHT }

class HeavyLifter {
  HeavyLifterDivision _division;
  HeavyLifterDivision get division => _division;

  HeavyLifter(HeavyLifterDivision this._division);

  List<String> get competitors => [];
}
