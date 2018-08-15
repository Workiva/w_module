import 'dart:io';
import 'dart:async';

import 'package:args/args.dart';

import 'src/utils.dart' as utils;

const String helpArg = 'help';
const String helpAbbr = 'h';
const String targetArg = 'target';
const String targetAbbr = 't';

final ArgParser argParser = new ArgParser()
  ..addOption(helpArg, abbr: helpAbbr, help: 'Shows this help')
  // TODO: this might not be feasible
  // consider doing targets in repocommander and just losing out on examples without a pubspec
  ..addOption(
    targetArg,
    abbr: targetAbbr,
    allowMultiple: true,
    help: 'Comma-delimited list of packages to ignore from validation.',
    splitCommas: true,
  );

void showHelpAndExit() {
  stdout.writeln(argParser.usage);
  exit(0);
}

Future main(List<String> args) async {
  ArgResults argResults;
  try {
    argResults = argParser.parse(args);
  } catch (e) {
    print('Error parsing args:\n${e.toString()}');
    showHelpAndExit();
  }

  if (argResults.wasParsed(helpArg) && argResults[helpArg]) {
    showHelpAndExit();
  }

  // Use of default values doesn't work with lists because it puts the whole
  // default object into a single-item list
  List<String> rawTargets = ['lib', 'example', 'examples', 'app'];
  if (argResults.wasParsed(targetArg)) {
    rawTargets = argResults[targetArg];
  }

  final List<String> targets = utils.getTargetsThatExist(rawTargets);

  if (targets.isEmpty) {
    stdout.writeln('No target entrypoints found. Tried: ${targets.toString}');
    exit(1);
  }

  final sdkDir = utils.getSdkDir();

  final context = utils.createAnalysisContext(sdkDir);

  final classes =
      utils.getClassesThatExtendFromModule(context, sdkDir, targets);

  classes.forEach(utils.writeGettersToFile);
//  utils.writeGettersToFile(classes.first);
}
