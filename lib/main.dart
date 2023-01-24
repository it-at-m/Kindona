import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:indoor_navigation/context/map_context.dart';
import 'package:indoor_navigation/map/extractor/beacon_extractor.dart';
import 'package:indoor_navigation/map/extractor/level_extractor.dart';
import 'package:indoor_navigation/map/extractor/room_extractor.dart';
import 'package:indoor_navigation/navigation/navigation.dart';
import 'package:indoor_navigation/views/home_view.dart';
import 'package:indoor_navigation/views/loading_view.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static const String mapsrc = 'assets/maps/campus_e.map';

  const MyApp({super.key});

  Future<MapContext> _initialize(Widget child) async {
    var map = await MapFile.using((await rootBundle.load(mapsrc)).buffer.asUint8List(), null, null);
    var indoorMap = await readEnvironment(map);
    var beacons = await BeaconExtractor.extractBeacons(map);
    var levels = await LevelExtractor.extractLevels(map);
    var rooms = await RoomExtractor.extractRooms(map);

    // Create the cache for assets
    final symbolCache = FileSymbolCache();

    final DisplayModel displayModel = DisplayModel(fontScaleFactor: 0.5);

    // Create the render theme which specifies how to render the informations
    // from the mapfile.
    final renderTheme = await RenderThemeBuilder.create(
      displayModel,
      'assets/render_themes/custom.xml',
    );

    // Create the Renderer
    final jobRenderer =
    MapDataStoreRenderer(map, renderTheme, symbolCache, true);

    var bitmapCache =
    await FileTileBitmapCache.create(jobRenderer.getRenderKey());
    bitmapCache.purgeAll();

    var viewModel = ViewModel(
        displayModel: displayModel,
        contextMenuBuilder: null // Remove default ContextMenuBuilder
    );

    viewModel.setZoomLevel(19);

    var context = MapContext(
        map: map,
        beacons: beacons,
        levels: levels,
        indoorMap: indoorMap,
        rooms: rooms,
        jobRenderer: jobRenderer,
        symbolCache: symbolCache,
        bitmapCache: bitmapCache,
        displayModel: displayModel,
        viewModel: viewModel,
        child: child);
    if (beacons.length >= 3) context.positionService.setBeacons(beacons);
    return context;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return
      MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(colorScheme: const ColorScheme.light()),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FutureBuilder(
              future: _initialize(const HomeView()),
              builder: (context, snapshot) =>
              snapshot.connectionState != ConnectionState.done ? const LoadingView()
                  : snapshot.requireData
          ),
      );
  }
}