import 'package:flutter/material.dart';
import 'package:indoor_navigation/map/overlay/position_overlay.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:indoor_navigation/map/overlay/indoor_level_bar.dart' as ilb;

import 'package:indoor_navigation/services/ble_service.dart';

class MapControlOverlay extends StatefulWidget {

  final ViewModel viewModel;
  final Map<int, String?>? indoorLevels;
  final void Function() onPressed;
  final Stream<Pos?> position;

  const MapControlOverlay({super.key, required this.viewModel, this.indoorLevels, required this.onPressed, required this.position});

  @override
  State<StatefulWidget> createState() => _MapControlOverlayState();

}

class _MapControlOverlayState extends State<MapControlOverlay> with SingleTickerProviderStateMixin  {
  static const kToolbarSpacing = 15.0;
  late AnimationController _fadeAnimationController;

  static const defaultIndoorlevels =  {
    5: null,
    4: null,
    3: null,
    2: "OG2",
    1: "OG1",
    0: "EG",
    -1: "UG1",
    -2: null,
    -3: null,
    -4: null,
    -5: null
  };

  @override
  void initState() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    super.initState();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _fadeAnimationController.forward();
    var topOffset = kToolbarHeight + MediaQuery.of(context).padding.top;
    return Positioned(
      right: kToolbarSpacing,
      top: topOffset,
      height: MediaQuery.of(context).size.height - topOffset - kToolbarSpacing,
      child: FadeTransition(
        opacity: _fadeAnimationController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            PositionOverlay(onPressed: widget.onPressed, position: widget.position),
            const SizedBox(height: 15),
            Flexible(
              child: ilb.IndoorLevelBar(
                onChange: (int level) {
                  widget.viewModel.setIndoorLevel(level);
                },
                indoorLevels: widget.indoorLevels ?? defaultIndoorlevels,
                width: 45,
                fillColor: Theme.of(context).buttonTheme.colorScheme!.background,
                elevation: 2.0,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                initialLevel: widget.viewModel.getIndoorLevel(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}