import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:indoor_navigation/context/map_context.dart';
import 'package:indoor_navigation/map/user_position_marker.dart';
import 'package:indoor_navigation/navigation/navigation.dart';
import 'package:indoor_navigation/services/selectedroute.dart';
import 'package:indoor_navigation/services/ble_service.dart';
import 'package:indoor_navigation/services/position_service.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';

import '../map/overlay/map_control_overlay.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}
class _MapViewState extends State<MapView> {

  late PositionService gps;
  Pos? _pos;
  late StreamSubscription sub;
  late StreamSubscription subRoute;
  MarkerByItemDataStore markerStore = MarkerByItemDataStore();

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      gps = MapContext
          .of(context)
          .positionService;
      gps.startPositioning();
    }

    var mapFile = MapContext.of(context).map;

    var viewModel = MapContext.of(context).viewModel;

    LatLong startPos = mapFile.startPosition?? _mapCenter();
    viewModel.setMapViewPosition(startPos.latitude, startPos.longitude);

    viewModel.addOverlay(MapControlOverlay(
        viewModel: viewModel,
        indoorLevels: MapContext.of(context).levels,
        onPressed: _setViewModelLocationToPosition,
        position: () => _pos
    ));
    viewModel.addOverlay(DistanceOverlay(viewModel));

    return FlutterMapView(mapModel: _createMapModel(context), viewModel: viewModel);
  }

  @override
  void initState() {
    super.initState();
    sub = PositionService.observe.listen((pos) => setState(() => _pos = pos));
    subRoute = SelectedRoute.observe.listen(_buildWayMarker);
  }

  @override
  void dispose() {
    sub.cancel();
    subRoute.cancel();
    tapListener?.cancel();
    positionListener?.cancel();
    roomListener?.cancel();
    if (!kIsWeb) {
      gps.stopPositioning();
    }
    super.dispose();
  }

  void _buildWayMarker(List<Room> route) {
    if (route.length >= 2) {
      markerStore.addMarker(
          fromPath(MapContext.of(context).displayModel,
              navigate(MapContext.of(context).indoorMap, route[0], route[1]).toList())
            ..item = "wayMarker"
      );
    }
  }

  StreamSubscription? tapListener;
  StreamSubscription? positionListener;
  StreamSubscription? roomListener;
  int? oldIndoorLevel;
  MapModel _createMapModel(BuildContext context) {
    var mapModel = MapModel(
      displayModel: MapContext.of(context).displayModel,
      renderer: MapContext.of(context).jobRenderer,
      tileBitmapCache: MapContext.of(context).bitmapCache,
      symbolCache: MapContext.of(context).symbolCache,
    );

    mapModel.markerDataStores
        .add(UserPositionMarker(displayModel: mapModel.displayModel, symbolCache: mapModel.symbolCache!));

    mapModel.markerDataStores.add(markerStore);

    _registerListeners(context);

    return mapModel;
  }

  _registerListeners(BuildContext context) {
    var viewModel = MapContext.of(context).viewModel;
    positionListener ??= viewModel.observePosition.listen((event) {
      if (oldIndoorLevel == null) {
        oldIndoorLevel = event.indoorLevel;
        return;
      }
      if (oldIndoorLevel! != event.indoorLevel) {
        MapContext.of(context).roomStream.value = null;
        oldIndoorLevel = event.indoorLevel;
        markerStore.removeMarkerWithItem("roomMarker");
      }
    });
    tapListener ??= viewModel.observeTap.listen((event) {
      final coords = LatLong(event.latitude, event.longitude);
      try {
        var hitRoom = MapContext.of(context).rooms.where((room) =>
            room.level == viewModel.getIndoorLevel())
            .firstWhere((room) => containsPoint(room.way, coords));
        MapContext.of(context).roomStream.value = hitRoom;
      } on StateError {
        //
      }
    }
    );
    roomListener ??= MapContext.of(context).observeSelectedRoom.listen((room) {
      if (room != null) {
        for (var shape in room.way.latLongs) {
          final marker = PolygonMarker(
              item: "roomMarker",
              strokeColor: 0x66666666,
              displayModel: MapContext.of(context).displayModel);
          for (var coord in shape) {
            marker.addLatLong(coord);
          }
          marker.initResources(MapContext.of(context).symbolCache).then((value) => markerStore.addMarker(marker));
        }
      }
    });
  }

  LatLong _mapCenter() {
    var map = MapContext.of(context).map;
    return LatLong(
        (map.boundingBox!.minLatitude + map.boundingBox!.maxLatitude) / 2,
        (MapContext.of(context).map.boundingBox!.minLongitude + map.boundingBox!.maxLongitude) / 2);
  }

  _setViewModelLocationToPosition() {
    var viewModel = MapContext.of(context).viewModel;
    if (_pos != null) {
      viewModel.setMapViewPosition(_pos!.lat, _pos!.lon);
    }
  }
}
