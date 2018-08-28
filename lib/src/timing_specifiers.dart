/// The type of 'startup timing metric' to be used by `specifyStartupTiming`
class StartupTimingType {
  /// The `operationName` to be used for spans created using this [StartupTimingType].
  final String name;

  const StartupTimingType._(this.name);

  /// Specifies the completion of the module's first render.
  static const StartupTimingType firstComponentRender =
      const StartupTimingType._('module_first_component_rendered');

  /// Specifies that the module is ready to respond to changes originated by the user.
  static const StartupTimingType firstEditable =
      const StartupTimingType._('module_entered_first_editable_state');

  /// Specifies that the module is now displaying useful information to the user.
  static const StartupTimingType firstReadable =
      const StartupTimingType._('module_entered_first_readable_state');

  /// Specifies that the module finished loading necessary data and is ready for user interaction.
  static const StartupTimingType firstUseful =
      const StartupTimingType._('module_entered_first_useful_state');
}
