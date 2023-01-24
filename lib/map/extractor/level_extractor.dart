import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';

class LevelExtractor {
  static Future<Map<int, String>> extractLevels(MapDataStore map) async {
    var bbox = [map.boundingBox!.minLongitude, map.boundingBox!.maxLongitude,
      map.boundingBox!.minLatitude, map.boundingBox!.maxLatitude];

    var projection = MercatorProjection.fromZoomlevel(18);
    var tileX1 = projection.longitudeToTileX(bbox[0]);
    var tileX2 = projection.longitudeToTileX(bbox[1]);
    var tileY1 = projection.latitudeToTileY(bbox[3]);
    var tileY2 = projection.latitudeToTileY(bbox[2]);

    var tile1 = Tile(tileX1, tileY1, 18, 0);
    var tile2 = Tile(tileX2, tileY2, 18, 0);

    var levels = await map.readPoiData(tile1, tile2)
        .then((value) => value!.pointOfInterests
        .map((e) => e.tags.where((e) => e.key == 'level').map((t) => t.value!))
        .expand((element) => element)
        .map((element) => element.split(";"))
        .expand((element) => element)
        .toSet().toList());

    levels.sort((a,b) => a.compareTo(b));
    Map<int, String> levelsMap = {};
    for (var i = 0; i < levels.length; ++i) {
      levelsMap.putIfAbsent(i, () => levels[i]);
    }

    return levelsMap;
  }
}