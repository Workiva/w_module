import 'package:w_module/w_module.dart';

class ModuleWithNameGetter extends Module {
  @override
  String get name => 'ModuleWithNameGetter';
}

class ModuleWithNameGetterSetter extends Module {
  @override
  String get name => 'ModuleWithNameGetterSetter';

  @override
  set name(String newName) {}
}

class ModuleWithNameSetter extends Module {
  @override
  String get name => 'ModuleWithNameSetter';

  @override
  set name(String newName) {}
}

class ModuleWithNameField extends Module {
  @override
  String name = 'ModuleWithNameField';
}

class ModuleWithFinalNameField extends Module {
  @override
  final String name = 'ModuleWithFinalNameField';
}
