import 'dart:async';
import 'package:opentracing/opentracing.dart';

class SampleSpan implements Span {
  static int _nextId = 0;
  final int _id = _nextId++;

  @override
  final List<Reference> references;

  @override
  final Map<String, dynamic> tags;

  @override
  final List<LogData> logData = [];

  @override
  final String operationName;

  @override
  SpanContext context;

  @override
  final DateTime startTime;

  DateTime _endTime;

  Completer<Span> _whenFinished = Completer<Span>();

  SampleSpan(
    this.operationName, {
    SpanContext childOf,
    this.references,
    DateTime startTime,
    Map<String, dynamic> tags,
  })  : this.startTime = startTime ?? DateTime.now(),
        this.tags = tags ?? {} {
    if (childOf != null) {
      references.add(Reference.childOf(childOf));
    }
    setTag('span.kind', 'client');

    final parent = parentContext;
    if (parent != null) {
      this.context = SpanContext(spanId: _id, traceId: parent.traceId);
      this.context.baggage.addAll(parent.baggage);
    } else {
      this.context = SpanContext(spanId: _id, traceId: _id);
    }
  }

  @override
  void addTags(Map<String, dynamic> newTags) => tags.addAll(newTags);

  @override
  Duration get duration => _endTime?.difference(startTime);

  @override
  DateTime get endTime => _endTime;

  @override
  void finish({DateTime finishTime}) {
    if (_whenFinished == null) {
      return;
    }

    _endTime = finishTime ?? DateTime.now();
    _whenFinished.complete(this);
    _whenFinished = null;
  }

  @override
  void log(String event, {dynamic payload, DateTime timestamp}) =>
      logData.add(LogData(timestamp ?? DateTime.now(), event, payload));

  @override
  SpanContext get parentContext =>
      references.isEmpty ? null : references.first.referencedContext;

  @override
  void setTag(String tagName, dynamic value) => tags[tagName] = value;

  @override
  set startTime(DateTime value) => startTime = value;

  @override
  Future<Span> get whenFinished => _whenFinished.future;

  @override
  String toString() {
    final sb = StringBuffer('SampleSpan(');
    sb
      ..writeln('traceId: ${context.traceId}')
      ..writeln('spanId: ${context.spanId}')
      ..writeln('operationName: $operationName')
      ..writeln('tags: ${tags.toString()}')
      ..writeln('startTime: ${startTime.toString()}');

    if (_endTime != null) {
      sb
        ..writeln('endTime: ${endTime.toString()}')
        ..writeln('duration: ${duration.toString()}');
    }

    if (logData.isNotEmpty) {
      sb.writeln('logData: ${logData.toString()}');
    }

    if (references.isNotEmpty) {
      final reference = references.first;
      sb.writeln(
          'reference: ${reference.referenceType} ${reference.referencedContext.spanId}');
    }

    sb.writeln(')');

    return sb.toString();
  }
}

class SampleTracer implements AbstractTracer {
  @override
  SampleSpan startSpan(
    String operationName, {
    SpanContext childOf,
    List<Reference> references,
    DateTime startTime,
    Map<String, dynamic> tags,
  }) {
    return SampleSpan(
      operationName,
      childOf: childOf,
      references: references,
      startTime: startTime,
      tags: tags,
    )..whenFinished.then((span) {
        print(span.toString());
      });
  }

  @override
  Reference childOf(SpanContext context) => Reference.childOf(context);

  @override
  Reference followsFrom(SpanContext context) => Reference.followsFrom(context);

  @override
  SpanContext extract(String format, dynamic carrier) {
    throw UnimplementedError(
        'Sample tracer for example purposes does not support advanced tracing behavior.');
  }

  @override
  void inject(SpanContext spanContext, String format, dynamic carrier) {
    throw UnimplementedError(
        'Sample tracer for example purposes does not support advanced tracing behavior.');
  }

  @override
  Future<dynamic> flush() {
    return null;
  }

  @override
  ScopeManager scopeManager;

  @override
  Span get activeSpan => scopeManager?.active?.span;
}
