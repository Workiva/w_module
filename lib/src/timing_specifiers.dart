class StartupTimingType {
  final String name;
  const StartupTimingType._(this.name);

  static const StartupTimingType firstComponentRender =
      const StartupTimingType._('module_first_component_rendered');

  static const StartupTimingType firstEditable =
      const StartupTimingType._('module_entered_first_editable_state');

  static const StartupTimingType firstReadable =
      const StartupTimingType._('module_entered_first_readable_state');

  static const StartupTimingType firstUseful =
      const StartupTimingType._('module_entered_first_useful_state');
}
