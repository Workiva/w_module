library w_module.src.deferred_module;

class DeferredModule {
  final dynamic apiClass;
  final dynamic componentsClass;
  final dynamic eventsClass;
  final dynamic moduleClass;

  const DeferredModule(this.moduleClass, this.apiClass, this.componentsClass, this.eventsClass);
}