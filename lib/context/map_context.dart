import 'package:flutter/material.dart';
import 'package:indoor_navigation/navigation/navigation.dart';
import 'package:indoor_navigation/services/ble_service.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:rxdart/rxdart.dart';

import '../services/position_service.dart';

class MapContext extends InheritedWidget {
  MapContext({
    Key? key,
    required child,
    required this.map,
    required this.beacons,
    required this.levels,
    required this.indoorMap,
    required this.rooms,
    required this.jobRenderer,
    required this.symbolCache,
    required this.bitmapCache,
    required this.displayModel,
    required this.viewModel,
  }) : super(key: key, child: child);

  final MapDataStore map;
  final List<Beacon> beacons;
  final Map<int, String> levels;
  final List<Room> rooms;
  final IndoorMap indoorMap;
  final JobRenderer jobRenderer;
  final SymbolCache symbolCache;
  final FileTileBitmapCache bitmapCache;
  final DisplayModel displayModel;
  final ViewModel viewModel;
  final PositionService positionService = PositionService();
  final BehaviorSubject<Room?> roomStream = BehaviorSubject();
  final BehaviorSubject<Room> navigateToStream = BehaviorSubject();

  Stream<Room?> get observeSelectedRoom => roomStream.stream;
  Stream<Room> get observeNavigateToRoom => navigateToStream.stream;

  static MapContext of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MapContext>()!;
  }

  @override
  bool updateShouldNotify(MapContext oldWidget) {
    return false;
  }
}