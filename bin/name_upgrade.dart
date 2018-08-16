import 'dart:io';
import 'dart:async';

import 'package:args/args.dart';

import 'src/utils.dart' as utils;

const String helpArg = 'help';
const String helpAbbr = 'h';
const String targetArg = 'target';
const String targetAbbr = 't';

final ArgParser argParser = new ArgParser()
  ..addOption(helpArg, abbr: helpAbbr, help: 'Shows this help');

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

  final List<String> targets = ['example', 'examples', 'app', 'dev-app'];

  utils.moveTargetsIntoLib(targets);

  final sdkDir = utils.getSdkDir();

  final context = utils.createAnalysisContext(sdkDir);

  utils
      .getClassesThatExtendFromModule(context, sdkDir)
      .forEach(utils.writeGettersToFile);

  utils.moveTargetsOutOfLib(targets);
}
