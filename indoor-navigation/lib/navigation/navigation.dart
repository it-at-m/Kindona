import 'dart:math';
import 'dart:ui';

import 'package:indoor_navigation/services/ble_service.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:indoor_navigation/map/IndoorPathMarker.dart';

class Navigation {

  Future<List<Room>> readEnvironment(MapFile map, Pos start, Pos end) async {
    var bbox_lon = [start.lon - 0.0001, start.lon + 0.0001,
      end.lon - 0.0001, end.lon + 0.0001];
    var bbox_lat = [start.lat - 0.0002, start.lat + 0.0002,
      end.lat - 0.0002, end.lat + 0.0002];
    bbox_lon.sort();
    bbox_lat.sort();

    var projection = MercatorProjection.fromZoomlevel(18);
    var tileX1 = projection.longitudeToTileX(bbox_lon[0]);
    var tileX2 = projection.longitudeToTileX(bbox_lon[3]);
    var tileY1 = projection.latitudeToTileY(bbox_lat[3]);
    var tileY2 = projection.latitudeToTileY(bbox_lat[0]);

    var tile1 = Tile(tileX1, tileY1, 18, 0);
    var tile2 = Tile(tileX2, tileY2, 18, 0);

    var result = await map.readMapData(tile1, tile2);

    List<WayNode> rooms = result.ways
        .where((e) => e.tags.any((t) => t.key == 'level'))
        .where((e) => e.tags.any((t) => t.key == 'indoor' && t.value != 'path'))
        .map((e) => wayToRoom(e)).fold(const Iterable<Room>.empty(), (p, e) => p.followedBy(e)).toList();
    var elevators = result.ways
        .where((e) => e.tags.any((t) => t.key == 'highway'))
        .where((e) => e.tags.any((t) => t.value == 'elevator'))
        .map((e) => wayToElevator(e)).toList();
    result.ways
        .where((e) => e.tags.any((t) => t.key == 'level'))
        .where((e) => e.tags.any((t) => t.key == 'indoor' && t.value == 'path'))
        .forEach((element) => addPathToRoom(element, rooms as List<Room>));
    print("Paths: ${
        result.ways
            .where((e) => e.tags.any((t) => t.key == 'level'))
            .where((e) => e.tags.any((t) => t.key == 'indoor' && t.value == 'path')).toList()}");
    result.pointOfInterests
        .where((e) => e.tags.any((t) => t.key == 'level'))
        .where((e) => e.tags.any((t) => t.key == 'door'))
        .forEach((e) => doorToEdge(e, const Iterable<WayNode>.empty().followedBy(rooms).followedBy(elevators).toList()));
    return rooms as List<Room>;
  }

  List<Node> navigate(Node from, Node to) {
    if (from == to) {
      return [];
    }

    // TODO: Use priority queue for proper Dijkstra
    List<DijkstraItem> visited = [];

    var newItems = [DijkstraItem(from, from, 0)];
    while (newItems.isNotEmpty) {
      var current = newItems[0];
      for (var edge in current.node.edges) {
        var exists = false;
        var pathWeight = current.weight + edge.weight;
        for (var node in visited) {
          if (edge.node.equals(node.node)) {
            exists = true;
            if (pathWeight < node.weight) {
              node.weight = pathWeight;
              node.from = current.node;
            }
          }
        }
        if (!exists) {
          var newItem = DijkstraItem(edge.node, current.node, pathWeight);
          visited.add(newItem);
          newItems.add(newItem);
        }
      }
      newItems.removeAt(0);
    }

    List<Node> path = [];
    var start = visited.firstWhere((element) => element.node.equals(to), orElse: () => visited[0]);
    if (start.node.equals(from)) {
      throw Exception('Could not reach node');
    }
    while (!start.node.equals(from)) {
      path.add(start.node);
      start = visited.firstWhere((e) => e.node.equals(start.from));
    }
    path.add(from);
    return path;
  }

  doorToEdge(PointOfInterest poi, List<WayNode> rooms) {
    var levels = poi.tags.where((e) => e.key == 'level').first.value!.split(';');
    for (var level in levels) {
      var door = Door(Pos(poi.position.latitude, poi.position.longitude), level);
      var links = <Room>[];
      for (var room in rooms.where((r) => r.hasLevel(level))) {
        var linked = room.way.latLongs.any((e) => e
            .any((e) => isSamePos(e, poi.position)));
        if (linked) {
          room.addEdge(Edge(1, door));
          door.addEdge(Edge(1, room));
        }
      }

      for (var room in links) {
        var edge = Edge(1, room);
        for (var r in links) {
          if (room == r) continue;
          r.addEdge(edge);
        }
      }
    }
  }

  addPathToRoom(Way path, List<Room> rooms) {
    var levels = path.tags.where((tag) => tag.key == 'level').first.value!.split(';');
    var ref = path.tags.where((tag) => tag.key == 'pathfor').first.value!;
    rooms.where((r) => r.name == ref)
      .where((r) => levels.any(r.hasLevel))
      .forEach((r) => r.addPath(path));
  }



  Elevator wayToElevator(Way way) {
    var pos = way.labelPosition?? way.latLongs[0][0];
    var levels = way.tags.where((e) => e.key == 'level').first;

    return Elevator(Pos(pos.latitude, pos.longitude), levels.value!, way);
  }

  List<Room> wayToRoom(Way way) {
    var pos = way.labelPosition?? way.latLongs[0][0];
    var nametags = way.tags.where((e) => e.key == 'ref' || e.key == 'name');
    var name = '';
    if (nametags.isNotEmpty) name = nametags.first.value!;
    var levels = way.tags.where((e) => e.key == 'level').first.value!.split(';');

    return levels.map((l) => Room(Pos(pos.latitude, pos.longitude), l, name, way)).toList();
  }

}

bool isSamePos(ILatLong left, ILatLong right)  {
  return (left.longitude - right.longitude).abs() < 0.000001 && (left.latitude - right.latitude).abs() < 0.000001;
}

class Graph {
  List<Node> nodes = [];
}

abstract class Node {
  Pos position;
  List<Edge> edges = [];
  bool accessibility;

  Node(this.position, {this.accessibility = true});

  void addEdge(Edge edge) => edges.add(edge);

  bool hasLevel(String level);

  List<String> getLevel();

  bool equals(Object other) {
    if (other is! Node) return false;
    return isSamePos(position, other.position);
  }

  @override
  bool operator==(Object other) {
    if (other is! Node) {
      return false;
    }

    if (position.lon != other.position.lon) return false;
    if (position.lat != other.position.lat) return false;

    return true;
  }

  @override
  int get hashCode => position.lon.hashCode+position.lat.hashCode;

}

abstract class WayNode extends Node {
  Way way;
  WayNode(super.position, this.way, {super.accessibility = true});
}

class Room extends WayNode {
  String name;
  String level;
  List<Way> paths = [];
  Room(super.position, this.level, this.name, super.way);
  @override
  bool hasLevel(String level) => level == this.level;

  @override
  List<String> getLevel() => [level];

  @override
  bool equals(Object other) {
    if (this != other) {
      return false;
    }
    if (other is! Room) {
      return false;
    }
    return level == other.level && name == other.name;
  }

  addPath(Way path) {
    paths.add(path);
  }

  bool hasPaths() => paths.isNotEmpty;

  List<ILatLong> findPath(ILatLong from, ILatLong to) {
    print("findPath: Room=$name hasPaths=${paths.isNotEmpty.toString()}");
    if (paths.isEmpty) {
      return [position];
    }
    var graph = _buildPathGraph();
    var start = closest(from, graph);
    var end = closest(to, graph);
    if (start == end) return [start.position];
    return Navigation().navigate(start, end).map((e) => e.position).toList().reversed.toList();
  }

  _buildPathGraph() {
    List<List<Node>> partials = [];
    // Convert each way to a list of nodes
    for (var ways in paths.map((e) => e.latLongs)) {
      for (var way in ways) {
        var partial = <Node>[];
        for (var i = 0; i < way.length; ++i) {
          partial.add(Door(Pos(way[i].latitude, way[i].longitude), level));
          if (i < 1) continue;
          partial[i-1].addEdge(Edge(1, partial[i]));
          partial[i].addEdge(Edge(1, partial[i-1]));
        }
        partials.add(partial);
      }
    }

    // Find common nodes in ways to form a connected graph
    // TODO: If there are consecutive nodes, that overlap, wrong graphs will
    // be produced. Only works if ways only overlap in a single node
    List<Node> graph = [...partials[0]];
    for (var way in partials.skip(1)) {
      for (var node in way) {
        var duplicate = false;
        for (var n in graph) {
          if (isSamePos(node.position, n.position)) {
            node.edges.forEach(n.addEdge);
            for (var edge in node.edges) {
              edge.node.edges.removeWhere((e) => e.node == node);
              edge.node.addEdge(Edge(1, n));
            }
          }
        }
        if (!duplicate) graph.add(node);
      }
    }
    return graph;
  }

  Node closest(ILatLong point, List<Node> graph) {
    return graph
        .map((e) => {'p': e, 'd': distance(point, e.position)})
        .reduce((v, e) => (v['d']! as double) < (e['d'] as double) ? v : e)['p'] as Node;
  }
}

class Door extends Node {
  String level;
  Door(super.position, this.level);
  @override
  bool hasLevel(String level) => level == this.level;
  @override
  List<String> getLevel() => [level];
  @override
  bool equals(Object other) {
    if (this != other) {
      return false;
    }
    if (other is! Door) {
      return false;
    }
    return isSamePos(position, other.position) && level == other.level;
  }
}

class Elevator extends WayNode {
  String level;
  Elevator(super.position, this.level, super.way);
  @override
  bool hasLevel(String level) => this.level.split(';').contains(level);
  @override
  List<String> getLevel() => level.split(';');
  @override
  bool equals(Object other) {
    if (this != other) {
      return false;
    }
    if (other is! Elevator) {
      return false;
    }
    return level == other.level;
  }
}

class Stair extends WayNode {
  String level;
  Stair(super.position, this.level, super.way) : super(accessibility: false);
  @override
  bool hasLevel(String level) => this.level.split(';').contains(level);
  @override
  List<String> getLevel() => level.split(';');
  @override
  bool equals(Object other) {
    if (this != other) {
      return false;
    }
    if (other is! Elevator) {
      return false;
    }
    return level == other.level;
  }
}

class Edge {
  int weight;
  Node node;
  Edge(this.weight, this.node);
}

class DijkstraItem {
  Node node;
  Node from;
  int weight;
  DijkstraItem(this.node, this.from, this.weight);
}

IndoorPathMarker fromPath(List<Node> nodes) {
  var path = IndoorPathMarker(minZoomLevel: 18);
  for (int i = 0; i < nodes.length; ++i) {
    var pos = nodes[i].position;
    if (nodes[i] is Stair || nodes[i] is Elevator) {
      if (i > 0) {
        path.addLatLong(IndoorLatLong(pos.lat, pos.lon, int.parse(nodes[i-1].getLevel()[0])));
      }
      if (i < nodes.length - 1) {
        path.addLatLong(IndoorLatLong(pos.lat, pos.lon, int.parse(nodes[i+1].getLevel()[0])));
      }
    } else if (nodes[i] is Room) {
      ILatLong start, end;
      if (i > 0) {
        start = nodes[i-1].position;
      } else {
        start = nodes[i].position;
      }
      if (i < nodes.length - 1) {
        end = nodes[i+1].position;
      } else {
        end = nodes[i].position;
      }

      var way = (nodes[i] as Room).findPath(start, end);
      print(way);
      for (var pos in way) {
        path.addLatLong(IndoorLatLong(pos.latitude, pos.longitude, int.parse(nodes[i].getLevel()[0])));
      }
    } else {
      path.addLatLong(IndoorLatLong(pos.lat, pos.lon, int.parse(nodes[i].getLevel()[0])));
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