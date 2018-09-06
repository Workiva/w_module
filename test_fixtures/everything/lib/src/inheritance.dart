import 'package:w_module/w_module.dart';

class NamedModule extends Module {
  @override
  String get name => 'NamedModule';
}

class UnnamedModule extends Module {}

class UnnamedModuleExtendsFromNamedModule extends NamedModule {}

class UnnamedModuleExtendsFromUnnamedModule extends UnnamedModule {}

class NamedModuleExtendsFromNamedModule extends NamedModule {
  @override
  String get name => 'NamedModuleExtendsFromNamedModule';
}

class NamedModuleExtendsFromUnnamedModule extends UnnamedModule {
  @override
  String get name => 'NamedModuleExtendsFromNamedModule';
}

class UnnamedUnnamedUnnamed extends UnnamedModuleExtendsFromUnnamedModule {}
class UnnamedUnnamedNamed extends UnnamedModuleExtendsFromNamedModule {}
class UnnamedNamedUnnamed extends NamedModuleExtendsFromUnnamedModule {}
class UnnamedNamedNamed extends NamedModuleExtendsFromNamedModule {}

class NamedUnnamedUnnamed extends UnnamedModuleExtendsFromUnnamedModule {
  @override
  String get name => 'NamedUnnamedUnnamed';
}
class NamedUnnamedNamed extends UnnamedModuleExtendsFromNamedModule {
  @override
  String get name => 'NamedUnnamedNamed';
}
class NamedNamedUnnamed extends NamedModuleExtendsFromUnnamedModule {
  @override
  String get name => 'NamedNamedUnnamed';
}
class NamedNamedNamed extends NamedModuleExtendsFromNamedModule {
  @override
  String get name => 'NamedNamedNamed';
}
