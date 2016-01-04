library w_module.build_file;

import 'package:source_gen/source_gen.dart';

import 'package:w_module/src/deferred_module_generator.dart';

void main(List<String> args) {
  build(args, const [
    const DeferredModuleGenerator()
  ], librarySearchPaths: ['example']).then((msg) {
    print(msg);
  });
}