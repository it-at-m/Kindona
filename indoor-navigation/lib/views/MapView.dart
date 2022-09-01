import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:indoor_navigation/map/BeaconExtractor.dart';
import 'package:indoor_navigation/map/PositionOverlay.dart';
import 'package:indoor_navigation/map/UserPositionMarker.dart';
import 'package:indoor_navigation/services/ble_service.dart';
import 'package:indoor_navigation/services/position_service.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';

class MapView extends StatefulWidget {
  final MapFile mapFile;

  const MapView({super.key, required this.mapFile});

  @override
  State<MapView> createState() => _MapViewState();
}
class _MapViewState extends State<MapView> {
  final DisplayModel displayModel = DisplayModel();

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
    // Glue everything together into two models.
    return mapModel;
  }

  Future<ViewModel> _createViewModel() {
    var model = ViewModel(displayModel: displayModel);
    model.setMapViewPosition(52.5211, 13.3905);
    model.setZoomLevel(16);
    model.addOverlay(IndoorlevelZoomOverlay(model,
      indoorLevels: const {1: 'OG', 0: 'EG', -1: 'UG'},
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
      BeaconExtractor.extractBeacons(widget.mapFile, _pos!)
          .then((value) { if (value.length >= 3) gps.setBeacons(value);});
    }
  }
}
