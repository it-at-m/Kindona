import 'package:mapsforge_flutter/datastore.dart';

import 'package:indoor_navigation/navigation/navigation.dart';

class RoomExtractor {
  static Future<List<Room>> extractRooms(MapDataStore map) async {
    return await readEnvironment(map)
    .then((nodes) => nodes.graph.keys.whereType<Room>().toList());
  }
}