/// The type of 'startup timing metric' to be used by `specifyStartupTiming`
class StartupTimingType {
  /// The `operationName` to be used for spans created using this [StartupTimingType].
  final String operationName;

  const StartupTimingType._(this.operationName);

  /// Specifies that the module finished loading necessary data and is ready for user interaction.
  static const StartupTimingType firstUseful =
      const StartupTimingType._('LifecycleModule.entered_first_useful_state');
}
