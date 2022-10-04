import 'package:indoor_navigation/services/ble_service.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';

class BeaconExtractor {

  static Future<List<Beacon>> extractBeacons(MapDataStore map, Pos location) {
    var bbox = [location.lon - 0.0001, location.lon + 0.0001,
      location.lat - 0.0002, location.lat + 0.0002];

    var projection = MercatorProjection.fromZoomlevel(18);
    var tileX1 = projection.longitudeToTileX(bbox[0]);
    var tileX2 = projection.longitudeToTileX(bbox[1]);
    var tileY1 = projection.latitudeToTileY(bbox[3]);
    var tileY2 = projection.latitudeToTileY(bbox[2]);

    var tile1 = Tile(tileX1, tileY1, 18, 0);
    var tile2 = Tile(tileX2, tileY2, 18, 0);

    return map.readPoiData(tile1, tile2)
        .then((value) => value!.pointOfInterests.where(
            (element) => element.tags.any((element) => element.key == 'indoor' && element.value == 'beacon')))
        .then((value) => value.map(poiToBeacon).toList());
  }

  static Beacon poiToBeacon(PointOfInterest poi) {
    var id = poi.tags.where((element) => element.key == 'id').first.value;
    var position = Pos(poi.position.latitude, poi.position.longitude);
    var b = Beacon(id!, position);
    return b;
  }

}