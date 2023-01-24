import 'package:flutter/material.dart';

import 'package:indoor_navigation/services/ble_service.dart';

class PositionOverlay extends StatefulWidget {
  late void Function() onPressed;
  late Pos? Function() position;

  PositionOverlay({Key? key, required this.onPressed, required this.position}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PositionOverlayState();
  }
}

class _PositionOverlayState extends State<PositionOverlay> {

  @override
  Widget build(BuildContext context) {
    Widget icon;
    if (widget.position() == null) {
      icon = Icon(Icons.location_searching_sharp, color:  Theme.of(context).disabledColor);
    } else {
      icon = Icon(Icons.my_location_sharp, color: Theme.of(context).buttonTheme.colorScheme!.primary);
    }
    return RawMaterialButton(
      onPressed: widget.onPressed,
      elevation: 2.0,
      fillColor: Theme.of(context).buttonTheme.colorScheme!.background,
      padding: const EdgeInsets.all(10.0),
      shape: const CircleBorder(),
      constraints: const BoxConstraints(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      child: icon,
    );
  }
}
