class StartupTimingSpecifier {
  final String name;
  const StartupTimingSpecifier._(this.name);

  static const StartupTimingSpecifier firstComponentRender =
      const StartupTimingSpecifier._('module_first_component_rendered');

  static const StartupTimingSpecifier firstEditable =
      const StartupTimingSpecifier._('module_entered_first_editable_state');

  static const StartupTimingSpecifier firstReadable =
      const StartupTimingSpecifier._('module_entered_first_readable_state');

  static const StartupTimingSpecifier firstUseful =
      const StartupTimingSpecifier._('module_entered_first_useful_state');
}
