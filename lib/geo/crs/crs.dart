library leaflet.geo.crs;

import 'dart:math' as math;

import '../geo.dart';
import '../projection/projection.dart' as proj;
import '../../geometry/geometry.dart' show Point2D, Transformation;

part 'epsg3395.dart';
part 'epsg3857.dart';
part 'epsg4326.dart';
part 'simple.dart';

/**
 * Defines coordinate reference systems for projecting geographical points
 * into pixel (screen) coordinates and back (and to coordinates in other units
 * for WMS services).
 *
 * CRS is a base object for all defined CRS (Coordinate Reference Systems) in Leaflet.
 */
abstract class CRS {

  final proj.Projection _projection;
  final Transformation _transformation;
  final String _code;

  CRS(this._projection, this._transformation, this._code);

  /**
   * Projection that this CRS uses.
   */
  proj.Projection get projection => _projection;

  /**
   * Transformation that this CRS uses to turn projected coordinates into
   * screen coordinates for a particular tile service.
   */
  Transformation get transformation => _transformation;

  /**
   * Standard code name of the CRS passed into WMS services (e.g. 'EPSG:3857').
   */
  String get code => _code;

  /**
   * Projects geographical coordinates on a given zoom into pixel coordinates.
   */
  Point2D latLngToPoint(LatLng latlng, num zoom) { // (LatLng, Number) -> Point
    final projectedPoint = projection.project(latlng);
    final s = scale(zoom);

    transformation.transformPoint(projectedPoint, s);
    return projectedPoint;
  }

  /**
   * The inverse of latLngToPoint. Projects pixel coordinates on a given zoom
   * into geographical coordinates.
   */
  LatLng pointToLatLng(Point2D point, num zoom) { // (Point, Number[, Boolean]) -> LatLng
    final s = scale(zoom);
    final untransformedPoint = transformation.untransform(point, s);

    return projection.unproject(untransformedPoint);
  }

  /**
   * Projects geographical coordinates into coordinates in units accepted for
   * this CRS (e.g. meters for EPSG:3857, for passing it to WMS services).
   */
  Point2D project(LatLng latlng) {
    return projection.project(latlng);
  }

  /**
   * Returns the scale used when transforming projected coordinates into pixel
   * coordinates for a particular zoom. For example, it returns 256 * 2^zoom
   * for Mercator-based CRS.
   */
  num scale(num zoom) {
    return 256 * math.pow(2, zoom);
  }

  /**
   * Returns the size of the world in pixels for a particular zoom.
   */
  Point2D getSize(num zoom) {
    var s = scale(zoom);
    return new Point2D(s, s);
  }
}