// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indoor_navigation/navigation/navigation.dart';
import 'package:mapsforge_flutter/maps.dart';

void main() async {
  var map = await MapFile.from('assets/maps/campus_e.map', null, null);
  var d = await readEnvironment(map);
  var from = d.graph.keys.whereType<Room>().where((e) => e.level == 2 && e.name == '1').first;
  var to = d.graph.keys.whereType<Room>().where((e) => e.level == 1 && e.name == '3').first;
  var path = navigate(d, from, to);
  print(path.toString());

}
