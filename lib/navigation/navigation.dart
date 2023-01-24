import 'dart:math';

import 'package:a_star/a_star.dart';
import 'package:epitaph_ips/epitaph_graphs/graphs/undirected_graph.dart';
import 'package:epitaph_ips/epitaph_graphs/path_finding/dijkstra.dart';
import 'package:epitaph_ips/epitaph_graphs/nodes/vertex.dart';
import 'package:epitaph_ips/epitaph_graphs/nodes/undirected_edge.dart';
import 'package:indoor_navigation/map/indoor_path_marker.dart';
import 'package:mapsforge_flutter/core.dart';

import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:polylabel/polylabel.dart';

class IndoorNode extends Vertex with Node<IndoorNode> {
  final ILatLong latLong;
  final int level;
  IndoorNode(super.id, {required this.latLong, required this.level});

  @override
  Vertex copy() => IndoorNode(id, latLong: latLong, level: level);

  @override
  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }
}

abstract class IndoorWay extends IndoorNode {
  final Way way;

  IndoorWay(super.id, {required super.latLong, required super.level, required this.way});
}

class Room extends IndoorWay {
  String name = '';
  List<Way> paths = [];
  final RoomType type;
  Room(super.id, {
    required super.latLong,
    required super.level,
    required super.way,
    required this.type,
    this.name = '',
  });

  factory Room.fromWay(Way way, int level) {
    final center = way.labelPosition ?? calculateCenter(way);
    final potentialName = way.tags.where((element) => ['ref', 'name'].contains(element.key)).map((e) => e.value);
    RoomType type = RoomType.none;
    var tags = way.tags.where((tag) => ['highway', 'amenity', 'stairs', 'indoor', 'female', 'male'].contains(tag.key));
    if (tags.any((tag) => tag.value == 'toilets')) {
      type = RoomType.toilet;
      if (tags.any((tag) => tag.key == 'male' && tag.key == 'yes')) {
        type = RoomType.toiletMale;
      } else if(tags.any((tag) => tag.key == 'female' && tag.key == 'yes')) {
        type = RoomType.toiletFemale;
      }
    } else if (tags.any((tag) => tag.value == 'corridor')) {
      type = RoomType.corridor;
    }

    return Room(Object.hash(hashWay(way), level).toString(),
        level: level.toInt(),
        latLong: center,
        type: type,
        way: way,
        name: potentialName.isNotEmpty ? potentialName.first! : '',
    );
  }

  bool hasPaths() => paths.isNotEmpty;

  List<ILatLong> findPath(ILatLong from, ILatLong to) {
    if (paths.isEmpty) {
      return [latLong];
    }
    var graph = _buildPathGraph();
    var start = closest(from, graph);
    var end = closest(to, graph);
    if (start == end) return [start.latLong];
    return navigate(graph, start, end).map((e) => e.latLong).toList();
  }

  IndoorMap _buildPathGraph() {
    var map = IndoorMap();
    List<List<IndoorNode>> partials = [];
    // Convert each way to a list of nodes
    for (var ways in paths.map((e) => e.latLongs)) {
      for (var way in ways) {
        var partial = <IndoorNode>[];
        for (var i = 0; i < way.length; ++i) {
          partial.add(IndoorNode(i.toString(), latLong: LatLong(way[i].latitude, way[i].longitude), level: level));
          if (i > 0) {
            map.connectNode(partial[i], partial[i-1]);
          }
        }
        partials.add(partial);
      }
    }

    // Find common nodes in ways to form a connected graph
    // TODO: If there are consecutive nodes, that overlap, wrong graphs will
    // be produced. Only works if ways only overlap in a single node
    List<IndoorNode> graph = [...partials[0]];
    for (var way in partials.skip(1)) {
      for (var node in way) {
        var duplicate = false;
        for (var n in graph) {
          if (isSamePos(node.latLong, n.latLong)) {
            map.connectNode(node, n);
          }
        }
        if (!duplicate) graph.add(node);
      }
    }
    return map;
  }

  IndoorNode closest(ILatLong point, IndoorMap graph) {
    return graph.graph.keys
        .map((e) => {'p': e, 'd': distance(point, (e as IndoorNode).latLong)})
        .reduce((v, e) => (v['d']! as double) < (e['d'] as double) ? v : e)['p'] as IndoorNode;
  }
}

class Elevator extends IndoorWay {
  final String group;

  Elevator(super.id, {required super.latLong, required super.level, required this.group, required super.way});

  factory Elevator.fromWay(Way way, int level, String group) {
    final center = calculateCenter(way);
    final elevator = Elevator(hashWay(way).toString(), level: level, group: group, latLong: center, way: way);
    return elevator;
  }
}

class Stairway extends IndoorWay {
  final String group;

  Stairway(super.id, {required super.latLong, required super.level, required this.group, required super.way});

  factory Stairway.fromWay(Way way, int level, String group) {
    final center = calculateCenter(way);
    final stairway = Stairway(hashWay(way).toString(), level: level, group: group, latLong: center, way: way);
    return stairway;
  }
}

class IndoorMap extends UndirectedGraph {
  // Node that represents the outside. Navigating from the outside and between buildings
  final IndoorNode outside = IndoorNode('outside', latLong: const LatLong(0,0), level: 0);

  IndoorMap() : super({}) {
    addNode(outside);
  }

  void addNode(IndoorNode v) {
    graph.putIfAbsent(v, () => <UndirectedEdge>[]);
  }

  void connectNode(IndoorNode a, IndoorNode b) {
    var edge = UndirectedEdge(a, b, 1); //distance(a.latLong, a.latLong));
    graph.putIfAbsent(a, () => <UndirectedEdge>[]).add(edge);
    graph.putIfAbsent(b, () => <UndirectedEdge>[]).add(edge.reversedEdge());
  }
}

Future<IndoorMap> readEnvironment(MapDataStore map) async {
  var projection = MercatorProjection.fromZoomlevel(18);
  var bbox = map.boundingBox!;
  var tileX1 = projection.longitudeToTileX(bbox.minLongitude);
  var tileX2 = projection.longitudeToTileX(bbox.maxLongitude);
  var tileY1 = projection.latitudeToTileY(bbox.maxLatitude);
  var tileY2 = projection.latitudeToTileY(bbox.minLatitude);

  var tile1 = Tile(tileX1, tileY1, 18, 0);
  var tile2 = Tile(tileX2, tileY2, 18, 0);

  var result = await map.readMapData(tile1, tile2);

  var indoorMap = IndoorMap();

  var rooms = result!.ways
      .where((e) => e.tags.any((t) => t.key == 'level'))
      .where((e) => e.tags.any((t) => t.key == 'indoor' && t.value != 'path'))
      .expand((e) => roomsFromWay(e))
      .toList(growable: true)
      ..forEach(indoorMap.addNode);

  result.ways
      .where((e) => e.tags.any((t) => t.key == 'highway' && t.value == 'elevator'))
      .expand((e) => elevatorFromWay(e, indoorMap));

  result.ways
      .where((e) => e.tags.any((t) => t.key == 'highway' && t.value == 'steps'))
      .expand((e) => stairwayFromWay(e, indoorMap));

  result.ways
      .where((e) => e.tags.any((t) => t.key == 'level'))
      .where((e) => e.tags.any((t) => t.key == 'indoor' && t.value == 'path'))
      .forEach((element) => addPathToRoom(element, rooms));

  result.pointOfInterests
      .where((e) => e.tags.any((t) => t.key == 'level'))
      .where((e) => e.tags.any((t) => t.key == 'door'))
      .forEach((e) => doorToEdge(e, indoorMap));
  return indoorMap;
}

Iterable<IndoorNode> navigate(IndoorMap map, IndoorNode from, IndoorNode to) {
  Dijkstra dijkstra = Dijkstra(map.graph);
  var path = dijkstra.solve(from, to);
  return path.path.map((e) => e as IndoorNode);
}

bool isSamePos(ILatLong left, ILatLong right)  {
  return (left.longitude - right.longitude).abs() < 0.000001 && (left.latitude - right.latitude).abs() < 0.000001;
}

doorToEdge(PointOfInterest poi, IndoorMap map) {
  var levels = poi.tags.where((e) => e.key == 'level').first.value!.split(';').map(int.parse);
  for (var level in levels) {
    var door = IndoorNode("door ${Random().nextInt(0xffff)}", latLong: LatLong(poi.position.latitude, poi.position.longitude), level: level);
    var links = map.graph.keys
        .where((r) => (r as IndoorNode).level == level)
        .whereType<IndoorWay>()
        .where((r) => r.way.latLongs.any((way) => way.any((p) => isSamePos(door.latLong, p))))
        .toList();

    for (var link in links) {
      map.connectNode(door, link);
    }

    // Door with only one connected room is considered to be an entry/exit
    if (links.length == 1) {
      map.connectNode(door, map.outside);
    }
  }
}

addPathToRoom(Way path, List<Room> rooms) {
  var levels = path.tags.where((tag) => tag.key == 'level').first.value!.split(';').map(int.parse);
  var ref = path.tags.where((tag) => tag.key == 'pathfor').first.value!;
  for (var r in rooms.where((r) => r.name == ref)
      .where((r) => levels.contains(r.level))) {
    r.paths.add(path);
  }
}

Iterable<Room> roomsFromWay(Way way) {
  return way.tags.where((element) => element.key == 'level')
      .map((e) => e.value)
      .expand((e) => e!.split(";"))
      .where((e) => e.isNotEmpty)
      .map(int.parse)
      .map((e) => Room.fromWay(way, e));
}

Iterable<Stairway> stairwayFromWay(Way way, IndoorMap indoorMap) {
  var stairway = way.tags.where((element) => element.key == 'level')
      .map((e) => e.value)
      .expand((e) => e!.split(";"))
      .where((e) => e.isNotEmpty)
      .map(int.parse)
      .map((e) => Stairway.fromWay(way, e, "Stairway ${Random().nextInt(0xffff)}"))
      .toList();

  for (int i = 0; i < stairway.length; i++) {
    for (int j = i+1; j < stairway.length; j++) {
      indoorMap.connectNode(stairway[i], stairway[j]);
    }
  }

  return stairway;
}

Iterable<Elevator> elevatorFromWay(Way way, IndoorMap indoorMap) {
  var elevators = way.tags.where((element) => element.key == 'level')
      .map((e) => e.value)
      .expand((e) => e!.split(";"))
      .where((e) => e.isNotEmpty)
      .map(int.parse)
      .map((e) => Elevator.fromWay(way, e, "Elevator ${Random().nextInt(0xffff)}"))
      .toList();

  for (int i = 0; i < elevators.length; i++) {
    for (int j = i+1; j < elevators.length; j++) {
      indoorMap.connectNode(elevators[i], elevators[j]);
    }
  }

  return elevators;
}

enum RoomType {
  none,
  corridor,
  toilet,
  toiletMale,
  toiletFemale,
  elevator,
  stairway,
}

int hashWay(Way way) {
  var hashLatLongs = Object.hashAll(way.latLongs.map((e) => Object.hashAll(e)));
  var hashTags = Object.hashAll(way.tags.map((e) => Object.hash(e.key, e.value)));
  return Object.hash(hashLatLongs, hashTags);
}

ILatLong calculateCenter(Way way) {
  final polygon = way.latLongs.map((shape) => shape.map((e) => Point<double>(e.latitude, e.longitude)).toList()).toList();
  final result = polylabel(polygon);
  return LatLong(result.point.x.toDouble(), result.point.y.toDouble());
}

IndoorPathMarker fromPath(DisplayModel displayModel, List<IndoorNode> nodes) {
  var path = IndoorPathMarker(displayModel: displayModel, minZoomLevel: 18);
  for (int i = 0; i < nodes.length; ++i) {
    var pos = nodes[i].latLong;
    if (nodes[i] is Room) {
      ILatLong start, end;
      if (i > 0) {
        start = nodes[i-1].latLong;
      } else {
        start = nodes[i].latLong;
      }
      if (i < nodes.length - 1) {
        end = nodes[i+1].latLong;
      } else {
        end = nodes[i].latLong;
      }
      var way = (nodes[i] as Room).findPath(start, end);
      for (var pos in way) {
        path.addLatLong(IndoorLatLong(pos.latitude, pos.longitude, nodes[i].level));
      }
    } else {
      path.addLatLong(
          IndoorLatLong(pos.latitude, pos.longitude, nodes[i].level));
    }
  }
  return path;
}

///
/// Calculates distance between two coordinates (WGS84) in meters
/// with the help of Vincenty's formulae
/// https://en.wikipedia.org/wiki/Vincenty%27s_formulae
///
double distance(ILatLong p1, ILatLong p2) {
  // length of semi-major axis of the ellipsoid (radius at equator in meters); (WGS-84)
  var a = 6378137.0;
  // flattening of the ellipsoid (WGS-84)
  var f = 1/298.257223563;
  // length of semi-minor axis of the ellipsoid (radius at the poles); b = (1 − ƒ) a
  var b = 6356752.314245;

  // Latitude in radians
  var phi_1 = (pi/180) * p1.latitude;
  var phi_2 = (pi/180) * p2.latitude;

  // reduced latitude (latitude on the auxiliary sphere)
  var u1 = atan((1-f)*tan(phi_1));
  var u2 = atan((1-f)*tan(phi_2));

  // Longitude in radians
  var l1 = (pi/180) * p1.longitude;
  var l2 = (pi/180) * p2.longitude;

  var L = l2 - l1;

  var lambda = L;

  num cos_alpha_squared = 0,
      sigma = 0,
      sin_sigma = 0,
      cos_2_sigma_m = 0,
      cos_sigma= 0
  ;
  for (int i = 0; i < 10; i++) {
    sin_sigma = sqrt(pow(cos(u2) * sin(lambda), 2) +
        pow(cos(u1) * sin(u2) - sin(u1) * cos(u2) * cos(lambda), 2));

    cos_sigma = sin(u1) * sin(u2) + cos(u1) * cos(u2) * cos(lambda);

    sigma = atan2(sin_sigma, cos_sigma);

    var sin_alpha = (cos(u1) * cos(u2) * sin(lambda)) / sin_sigma;

    cos_alpha_squared = (1 - pow(sin_alpha, 2));

    cos_2_sigma_m = cos(sigma) -
        ((2 * sin(u1) * sin(u2)) / cos_alpha_squared);

    var C = (f / 16) * cos_alpha_squared *
        (4 + (f * (4 - (3 * cos_alpha_squared))));

    lambda = L + (1 - C) * f * sin_alpha * (sigma + C * sin_sigma *
        (cos_2_sigma_m + C * cos_sigma * (-1 + 2 * pow(cos_2_sigma_m, 2))));
  }

  var u_squared = cos_alpha_squared * ((pow(a,2)-pow(b,2))/pow(b,2));

  var A = 1 + (u_squared / 16384) * (4096 + u_squared * (-768 + u_squared + (320 - (175 * u_squared))));

  var B = (u_squared / 1024) * (256 + u_squared * (-128+ u_squared * (74 - (47 * u_squared))));

  var delta_sigma = B * sin_sigma * (cos_2_sigma_m + (0.25 * B * (cos_sigma*(-1+2*pow(cos_2_sigma_m, 2))-((B/6)*cos_2_sigma_m*(-3+4*pow(sin_sigma, 2))*(-3+4*pow(cos_2_sigma_m, 2))))));

  var s = b * A * (sigma-delta_sigma);

  /* dead code for azimuth calculation currently not needed, but who knows, might come handy in the future
    var alpha_1 = atan2(cos(u2)*sin(lambda), cos(u1)*sin(u2)-sin(u1)*cos(u2)*cos(lambda));
    var alpha_2 = atan2(cos(u1)*sin(lambda), -sin(u1)*cos(u2)+cos(u1)*sin(u2)*cos(lambda));
    */
  return s;
}

// Ray casting method for figuring out if a point is inside a polygon
bool containsPoint(Way way, ILatLong point) {
  var result = false;

  for (var shape in way.latLongs) {
    // Start with last and first vertex of shape because the shape is closed
    int j = shape.length - 1;
    for (int i = 0; i < shape.length; i++) {
      if ((shape[i].longitude < point.longitude &&
          shape[j].longitude >= point.longitude) ||
          (shape[i].longitude >= point.longitude &&
              shape[j].longitude < point.longitude)) {
        if (shape[i].latitude + (point.longitude - shape[i].longitude) / (shape[j].longitude - shape[i].longitude) * (shape[j].latitude - shape[i].latitude) < point.latitude)
        {
          result = !result;
        }
      }
      j = i;
    }
    if (result) {
      return true;
    }
  }

  return result;
}