library dartsy.utils;

import 'dart:math';

/// Get azimuth angle clockwise from "true north", or "up" in our case.
num getAngleBetweenPoints(Point a, Point b) {
  // Reverse y since y-axis increases downward in graphics.
  var angle = 90 - (180 / PI) * atan2(a.y - b.y, b.x - a.x);
  return (angle < 0) ? 360 + angle : angle;
}

Point getRotatedPoint(Point focus, Point origin, num angle) {
  var a = angle * PI / 180;
  // Subtract midpoints, so that midpoint is translated to origin
  // and add it in the end again
  var xm = (focus.x - origin.x);
  var ym = (focus.y - origin.y);
  var xr = xm * cos(a) - ym * sin(a) + origin.x;
  var yr = ym * cos(a) + xm * sin(a) + origin.y;
  return new Point(xr, yr);
}
