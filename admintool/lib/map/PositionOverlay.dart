import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class PositionOverlay extends StatefulWidget {
  late void Function() onPressed;
  late Position? Function() position;

  PositionOverlay({Key? key, required this.onPressed, required this.position}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PositionOverlayState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class _PositionOverlayState extends State<PositionOverlay>
    with SingleTickerProviderStateMixin {
  final double toolbarSpacing = 15;

  late AnimationController _fadeAnimationController;
  late CurvedAnimation _fadeAnimation;

  @override
  PositionOverlay get widget => super.widget;

  @override
  void initState() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      //value: 1,
      vsync: this,
      //lowerBound: 0,
      //upperBound: 1,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.ease,
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
    Widget icon;
    if (widget.position() == null) {
      icon = const Icon(Icons.location_searching_sharp, color:  Colors.black);
    } else {
      icon = const Icon(Icons.my_location_sharp, color: Colors.blue);
    }
    return Positioned(
      bottom: toolbarSpacing,
      right: toolbarSpacing,
      top: toolbarSpacing,
      // this widget has an unbound width
      // left: toolbarSpacing,
      child: FadeTransition(
        opacity: _fadeAnimationController,
        child: Column(
          children: [
            RawMaterialButton(
              onPressed: widget.onPressed,
              elevation: 2.0,
              fillColor: Colors.white,
              child: icon,
              padding: const EdgeInsets.all(10.0),
              shape: const CircleBorder(),
              constraints: const BoxConstraints(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          ],
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      ),
    );
  }
}
