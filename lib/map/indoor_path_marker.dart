import 'dart:math';

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/marker.dart';

class IndoorPathMarker extends PathMarker {

  IndoorPathMarker({
    minZoomLevel = 0,
    maxZoomLevel = 65535,
    item,
    strokeWidth = 2.0,
    strokeColor = 0xff0000ff,
    required DisplayModel displayModel
  })  : super(
        displayModel: displayModel,
        minZoomLevel: minZoomLevel,
        maxZoomLevel: maxZoomLevel,
        item: item,
        strokeWidth: strokeWidth,
        strokeColor: strokeColor,
      );

  int _zoom = -1;

  int _indoorLevel = -65535;

  double _leftUpperX = -1;

  double _leftUpperY = -1;

  @override
  void addLatLong(ILatLong latLong) {
    super.addLatLong(latLong);
    _zoom = -1;
    _indoorLevel = -65535;
  }

  @override
  void render(MarkerCallback markerCallback) {
    if (_zoom != markerCallback.mapViewPosition.zoomLevel || _indoorLevel != markerCallback.mapViewPosition.indoorLevel) {
      mapPath?.clear();
      _zoom = markerCallback.mapViewPosition.zoomLevel;
      _indoorLevel = markerCallback.mapViewPosition.indoorLevel;
      for (var latLong in path) {
        if (latLong is IndoorLatLong && latLong.indoorLevel != _indoorLevel) {
          continue;
        }

        var mappoint = _projectLatLongOnMap(markerCallback.mapViewPosition.projection!, latLong);
        double y = mappoint.y - markerCallback.mapViewPosition.leftUpper!.y;
        double x = mappoint.x - markerCallback.mapViewPosition.leftUpper!.x;

        if (mapPath!.isEmpty()) {
          mapPath!.moveTo(x, y);
        } else {
          mapPath!.lineTo(x, y);
        }
      }
      _leftUpperX = markerCallback.mapViewPosition.leftUpper!.x;
      _leftUpperY = markerCallback.mapViewPosition.leftUpper!.y;
    }

    markerCallback.flutterCanvas.uiCanvas.save();
    markerCallback.flutterCanvas.uiCanvas.translate(
      _leftUpperX - markerCallback.mapViewPosition.leftUpper!.x,
     _leftUpperY - markerCallback.mapViewPosition.leftUpper!.y);
    markerCallback.renderPath(
      mapPath!, getStrokePaint(markerCallback.mapViewPosition.zoomLevel));
    markerCallback.flutterCanvas.uiCanvas.restore();
  }

  Mappoint _projectLatLongOnMap(PixelProjection projection, ILatLong latLong) {
    Mappoint mappoint = Mappoint(
        projection.longitudeToPixelX(latLong.longitude),
        projection.latitudeToPixelY(latLong.latitude));
    return mappoint;
  }
}

class IndoorLatLong implements ILatLong {

  @override
  final double latitude;

  @override
  final double longitude;

  final int indoorLevel;

  IndoorLatLong(this.latitude, this.longitude, this.indoorLevel);
}

/// A Point represents an immutable pair of double coordinates in screen pixels.
class Mappoint {
  /// The x coordinate of this point in pixels. Positive values points towards
  /// the right side of the screen.
  final double x;

  /// The y coordinate of this point in pixels. Positive values points to
  /// the bottom of the screen.
  final double y;

  /// @param x the x coordinate of this point.
  /// @param y the y coordinate of this point.
  const Mappoint(this.x, this.y);

  /// @return the euclidian distance from this point to the given point.
  double distance(Mappoint point) {
    return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Mappoint &&
              runtimeType == other.runtimeType &&
              x == other.x &&
              y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  Mappoint offset(double dx, double dy) {
    if (0 == dx && 0 == dy) {
      return this;
    }
    return Mappoint(x + dx, y + dy);
  }

  @override
  String toString() {
    return 'Point{x: $x, y: $y}';
  }
}