library dartsy.dartsy_module;

import 'components.dart';
import 'context.dart';

class Configuration {
  String containerId;

  Configuration(this.containerId) {
    if (containerId == null) throw new ArgumentError.notNull('containerId');
  }
}

class Module {
  Context _context;

  /**
   * Drawing View Component
   */
  Object get component {
    return canvas({'context': _context});
  }

  Module(Configuration configuration) {
    _context = new Context(configuration);
  }

  Actions get actions => _context.actions;
  GraphicStore get graphicStore => _context.graphicStore;
  SelectionStore get selectionStore => _context.selectionStore;
  ShapeSettings get shapeSettings => _context.shapeSettings;
}
