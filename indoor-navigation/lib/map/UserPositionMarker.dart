import 'dart:async';

import 'package:indoor_navigation/services/position_service.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';

import '../services/ble_service.dart';

/// a Datastore holds markers and decides which markers to show for a given zoomLevel
/// and boundary. This example is a bit more complex. Initially we do not have
/// any morkers but we can add some with the contextMenu. The contextMenu adds
/// items to the "database" and the database triggers events. This datastore
/// listens to these events and updates the UI accordingly.
/// This example reflects a real-world example with async changes. I hope it
/// clarifies a lot.
class UserPositionMarker extends MarkerByItemDataStore {
  final SymbolCache symbolCache;

  Pos? position;

  UserPositionMarker({required this.symbolCache, this.position}) {
    PositionService.observe.listen((pos) { position = pos; setRepaint(); });
  }

  @override
  Future<void> retrieveMarkersFor(BoundingBox boundary, int zoomLevel) async {
    if (position != null && boundary.contains(position!.lat, position!.lon)) {
      addMarker(await _createMarker());
    }
  }

  Future<Marker> _createMarker() async {
    PoiMarker marker = PoiMarker(
      latLong: LatLong(position!.lat, position!.lon),
      src: "packages/mapsforge_flutter/assets/symbols/dot_blue.svg",
      width: 80,
      height: 80,
    );
    await marker.initResources(symbolCache);
    return marker;
  }
}