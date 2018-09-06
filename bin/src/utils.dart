import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';

final RegExp newLinePartOfRegexp = new RegExp('\npart of ');
final RegExp partOfRegexp = new RegExp('part of ');

void writeGettersForSource(Source source, List<ClassElement> classes) {
  // Sort descending to modify the bottom classes before the top
  classes.sort((a, b) => b.computeNode().end - a.computeNode().end);

  classes.forEach(writeGetterForClass);
}

void writeGetterForClass(ClassElement e) {
  final ePath = e.source.uri.path;

  String filePath = ePath.substring(ePath.indexOf('/') + 1);

  File f = new File('lib/$filePath');
  if (!f.existsSync()) {
    stdout.writeln('Does not exist: ${f.path}');
    exit(1);
  }

  final StringBuffer outputLines = new StringBuffer();

  final source = f.readAsStringSync();
  // The offset of the end of the class's opening '{' bracket token
  // ignore: avoid_as
  final insertionOffset = (e.computeNode() as ClassDeclaration).leftBracket.end;

  outputLines
    ..writeln(source.substring(0, insertionOffset))
    ..writeln('  @override')
    ..writeln('  String get name => \'${e.name}\';')
    ..write(source.substring(insertionOffset));

  f.writeAsStringSync(outputLines.toString());
}

void runMoveCommand(String from, String to) {
  Process.runSync('mv', [from, to]);
}

void moveTargetsIntoLib(List<String> targets) {
  targets.forEach((target) {
    runMoveCommand(target, tempNameForTarget(target));
  });
}

void moveTargetsOutOfLib(List<String> targets) {
  targets.forEach((target) {
    runMoveCommand(tempNameForTarget(target), target);
  });
}

String tempNameForTarget(String target) => 'lib/w_module_temp_$target';
