library tool.dev;

import 'package:dart_dev/dart_dev.dart' show dev, config;

main(List<String> args) async {
  // https://github.com/Workiva/dart_dev

  List<String> directories = ['example/', 'lib/', 'test/', 'tool/'];
  config.analyze.entryPoints = directories;
  config.copyLicense.directories = directories;
  config.format.directories = directories;

  await dev(args);
}
