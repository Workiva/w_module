import 'package:w_module/w_module.dart';

class NamedModule extends Module {
  @override
  String get name => 'NamedModule';
}

class UnnamedModule extends Module {
  @override
  final String name = 'UnnamedModule';
}

class UnnamedModuleExtendsFromNamedModule extends NamedModule {
  @override
  final String name = 'UnnamedModuleExtendsFromNamedModule';
}

class UnnamedModuleExtendsFromUnnamedModule extends UnnamedModule {
  @override
  final String name = 'UnnamedModuleExtendsFromUnnamedModule';
}

class NamedModuleExtendsFromNamedModule extends NamedModule {
  @override
  String get name => 'NamedModuleExtendsFromNamedModule';
}

class NamedModuleExtendsFromUnnamedModule extends UnnamedModule {
  @override
  String get name => 'NamedModuleExtendsFromNamedModule';
}

class UnnamedUnnamedUnnamed extends UnnamedModuleExtendsFromUnnamedModule {
  @override
  final String name = 'UnnamedUnnamedUnnamed';
}
class UnnamedUnnamedNamed extends UnnamedModuleExtendsFromNamedModule {
  @override
  final String name = 'UnnamedUnnamedNamed';
}
class UnnamedNamedUnnamed extends NamedModuleExtendsFromUnnamedModule {
  @override
  final String name = 'UnnamedNamedUnnamed';
}
class UnnamedNamedNamed extends NamedModuleExtendsFromNamedModule {
  @override
  final String name = 'UnnamedNamedNamed';
}

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
