import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:indoor_navigation/map/BeaconExtractor.dart';
import 'package:indoor_navigation/map/PositionOverlay.dart';
import 'package:indoor_navigation/map/UserPositionMarker.dart';
import 'package:indoor_navigation/navigation/navigation.dart';
import 'package:indoor_navigation/services/ble_service.dart';
import 'package:indoor_navigation/services/position_service.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/marker.dart';

class MapView extends StatefulWidget {
  final MapFile mapFile;

  const MapView({super.key, required this.mapFile});

  @override
  State<MapView> createState() => _MapViewState();
}
class _MapViewState extends State<MapView> {
  final DisplayModel displayModel = DisplayModel(fontScaleFactor: 0.5);

  final PositionService gps = PositionService();
  Pos? _pos;
  ViewModel? viewModel;
  late StreamSubscription sub;

  @override
  Widget build(BuildContext context) {
    return MapviewWidget(displayModel: displayModel, createMapModel: _createMapModel, createViewModel: _createViewModel);
  }

  @override
  void initState() {
    super.initState();
    sub = PositionService.observe.listen((pos) => setState(() => {_pos = pos}));
    gps.startPositioning();
  }

  @override
  void dispose() {
    gps.stopPositioning();
    sub.cancel();
    super.dispose();
  }

  Future<MapModel> _createMapModel() async {
    // Create the cache for assets
    final symbolCache = FileSymbolCache(rootBundle);

    // Create the render theme which specifies how to render the informations
    // from the mapfile.
    final renderTheme = await RenderThemeBuilder.create(
      displayModel,
      'assets/render_themes/custom.xml',
    );

    // Create the Renderer
    final jobRenderer =
    MapDataStoreRenderer(widget.mapFile, renderTheme, symbolCache, true);

    var bitmapCache =
        await FileTileBitmapCache.create(jobRenderer.getRenderKey());
    bitmapCache.purgeAll();

    var mapModel = MapModel(
      displayModel: displayModel,
      renderer: jobRenderer,
      tileBitmapCache: bitmapCache,
      symbolCache: symbolCache,
    );

    mapModel.markerDataStores
        .add(UserPositionMarker(symbolCache: symbolCache));

    var mapBbox = widget.mapFile.boundingBox;
    var rooms = await Navigation()
        .readEnvironment(widget.mapFile,  Pos(mapBbox.maxLatitude, mapBbox.minLongitude), Pos(mapBbox.minLatitude, mapBbox.maxLongitude));

    BeaconExtractor.extractBeacons(widget.mapFile)
        .then((value) { if (value.length >= 3) gps.setBeacons(value);});

    var from = rooms[0];


    var to = rooms.where((e) => e.level == '1' && e.name == '3').first;
    var store = MarkerDataStore();
    store.addMarker(
      fromPath(Navigation().navigate(from, to))
    );
    mapModel.markerDataStores.add(store);
    // Glue everything together into two models.
    return mapModel;
  }

  Future<ViewModel> _createViewModel() {
    var model = ViewModel(displayModel: displayModel);
    model.setMapViewPosition(52.5211, 13.3905);
    model.setZoomLevel(16);
    model.addOverlay(IndoorlevelZoomOverlay(model,
      indoorLevels: const {6: '6', 5: '5', 4: '4', 3: '3', 2: '2', 1: '1', 0: 'EG'},
    ));
    model.addOverlay(DistanceOverlay(model));
    model.addOverlay(PositionOverlay(onPressed: _setViewModelLocationToPosition, position: () => _pos));

    model.setMapViewPosition(48.17681816301853, 11.534292173877581);
    model.setZoomLevel(18);
    viewModel = model;
    return Future.value(model);
  }

  _setViewModelLocationToPosition() {
    if (viewModel != null && _pos != null) {
      viewModel!.setMapViewPosition(_pos!.lat, _pos!.lon);
    }
  }
}
