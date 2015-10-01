part of dartsy.context;

Point _getPointFromMouseEvent(MouseEvent event, Element container) {
  var clientRect = container.getBoundingClientRect();
  return new Point(event.page.x - clientRect.left, event.page.y - clientRect.top);
}

Point _getAnchorPointForResizeHandle(String handle, Rectangle rect) {
  switch (handle) {
    case Directions.NW:
      return new Point(rect.right, rect.bottom);
    case Directions.NE:
      return new Point(rect.left, rect.bottom);
    case Directions.SW:
      return new Point(rect.right, rect.top);
    default: // case Directions.SE:
      return new Point(rect.left, rect.top);
  }
}

String _getDirectionFromPoints(Point anchor, Point focus) {
  var angle = getAngleBetweenPoints(anchor, focus);
  if (0 <= angle && angle < 90) {
    return Directions.NE;
  } else if (90 <= angle && angle < 180) {
    return Directions.SE;
  } else if (180 <= angle && angle < 270) {
    return Directions.SW;
  } else { // if (270 <= angle && angle < 360)
    return Directions.NW;
  }
}

Rectangle _getNewBoundingRect(Point anchor, Point focus, Rectangle boundingRect, bool preserveAspectRatio) {
  var newBoundingRect = new Rectangle.fromPoints(anchor, focus);
  if (preserveAspectRatio) {
    var ratioX = newBoundingRect.width / boundingRect.width;
    var ratioY = newBoundingRect.height / boundingRect.height;
    var ratio = max(ratioX, ratioY);
    num width, height;
    if (ratio.isFinite) {
      width = boundingRect.width * ratio;
      height = boundingRect.height * ratio;
    } else {
      width = height = max(newBoundingRect.width, newBoundingRect.height);
    }
    var left = newBoundingRect.left == anchor.x ?
        newBoundingRect.left : newBoundingRect.right - width;
    var top = newBoundingRect.top == anchor.y ?
        newBoundingRect.top : newBoundingRect.bottom - height;
    return new Rectangle(left, top, width, height);
  } else {
    return newBoundingRect;
  }
}

