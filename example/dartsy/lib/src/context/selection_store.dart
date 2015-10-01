part of dartsy.context;

class SelectionStore extends Store {

  Context _context;
  Graphic _selection;

  SelectionStore(this._context) {
    triggerOnAction(_context.actions.graphicChanged, _handleGraphicChanged);
    triggerOnAction(_context.actions.graphicRemoved, _handleGraphicRemoved);
  }

  Graphic get selection => _selection;
  set selection(Graphic value) {
    if (_selection == value) {
      return;
    }
    _selection = value;
    _dispatchChanged();
  }

  Rectangle getBoundingBox() => _selection.getBoundingBox();

  void _dispatchChanged() {
    // TODO - this is emitting an external event so let's switch this from action to event
    _context.actions.selectionChanged();
  }

  void _handleGraphicChanged(Graphic graphic) {
    if (graphic == _selection) {
      _dispatchChanged();
    }
  }

  void _handleGraphicRemoved(Graphic graphic) {
    if (graphic == _selection) {
      selection = null;
    }
  }
}
