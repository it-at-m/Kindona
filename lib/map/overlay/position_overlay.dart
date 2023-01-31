import 'dart:async';

import 'package:flutter/material.dart';

import 'package:indoor_navigation/services/ble_service.dart';

class PositionOverlay extends StatefulWidget {
  final void Function() onPressed;
  final Stream<Pos?> position;

  const PositionOverlay({Key? key, required this.onPressed, required this.position}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PositionOverlayState();
  }
}

class _PositionOverlayState extends State<PositionOverlay> {

  late StreamSubscription sub;
  bool positioned = false;

  @override
  void initState() {
    super.initState();
    sub = widget.position.listen((event) {
      if (positioned != (event != null)) {
        setState(() {
          positioned = event != null;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    sub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    Widget icon;
    if (positioned) {
      icon = Icon(Icons.my_location_sharp, color: Theme.of(context).buttonTheme.colorScheme!.primary);
    } else {
      icon = Icon(Icons.location_searching_sharp, color:  Theme.of(context).disabledColor);
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
