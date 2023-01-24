import 'package:flutter/material.dart';
import 'package:indoor_navigation/views/map_view.dart';
import 'package:indoor_navigation/views/top_bar.dart';

import 'bottom_bar.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});


  @override
  Widget build(BuildContext context) {
    var mainWidget = const Scaffold(
      body: MapView(),
    );

    var widgets = <Widget>[
      mainWidget,
      const TopBar(),
      const BottomBar(),
    ];
    return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
        body: Stack(
            fit: StackFit.expand,
            children: widgets
        )

    );
  }
}
