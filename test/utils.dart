import 'package:logging/logging.dart';
import 'package:matcher/matcher.dart';

/// Provides a Matcher for [LogRecord].
///
/// The [Matcher] only considers provided optional parameters.
Matcher logRecord({Level level, Matcher message, Matcher loggerName}) {
  var matchers = [];
  if (level != null) {
    matchers.add(new _LogLevelMatcher(level));
  }
  if (message != null) {
    matchers.add(new _LogMessageMatcher(message));
  }
  if (loggerName != null) {
    matchers.add(new _LoggerNameMatcher(loggerName));
  }

  return allOf(matchers);
}

class _LogLevelMatcher extends Matcher {
  final Level _level;

  _LogLevelMatcher(this._level);

  @override
  Description describe(Description description) =>
      description.add('with $_level log level');

  @override
  bool matches(dynamic record, Map matchState) {
    if (_level == null) {
      return false;
    }
    if (record is LogRecord) {
      return record.level == _level;
    }
    return false;
  }
}

class _LogMessageMatcher extends Matcher {
  final Matcher _messageMatcher;

  _LogMessageMatcher(this._messageMatcher);

  @override
  Description describe(Description description) =>
      description.add('log message ').addDescriptionOf(_messageMatcher);

  @override
  bool matches(dynamic record, Map matchState) {
    if (record is LogRecord) {
      return _messageMatcher.matches(record.message, matchState);
    }
    return false;
  }
}

class _LoggerNameMatcher extends Matcher {
  final Matcher _nameMatcher;

  _LoggerNameMatcher(this._nameMatcher);

  @override
  Description describe(Description description) =>
      description.add('logger name ').addDescriptionOf(_nameMatcher);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is LogRecord) {
      return _nameMatcher.matches(item.loggerName, matchState);
    }
    return false;
  }
}
