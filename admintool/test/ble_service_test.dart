import 'dart:math';

import 'package:admintool/services/ble_service.dart';
import 'package:epitaph_ips/epitaph_ips/buildings/point.dart';

void main() {

  var p1 = Pos(11.532329596173419, 48.176901466583985);
  var p2 = Pos(11.532814800111955, 48.176893726152855);

  var service = CoordinationSystemConverter(p1);

  var d = service.distance(p1, p2);

  var p3 = Pos(11.532329596173419, 48.176893726152855);
  var p4 = Pos(11.532814800111955, 48.176901466583985);
  var d1 = service.distance(p1, p3);
  var d2 = service.distance(p1, p4);

  print('d: ' + d.toString());
  print('d12: ' + sqrt(pow(d1, 2) + pow(d2, 2)).toString());

  var p = service.geographicToCartesian(p2);
  print(p.x);
  print(p.y);

  var up = Point(1000000, 50000);

  var u = service.cartesianToGeographic(up);

  print('u.lat: ' + u.lat.toString());
  print('u.lon: ' + u.lon.toString());

  var ur = service.geographicToCartesian(u);

  print('ur.x: ' + ur.x.toString());
  print('ur.y: ' + ur.y.toString());

  u = service.cartesianToGeographic(ur);

  print('u.lat: ' + u.lat.toString());
  print('u.lon: ' + u.lon.toString());ur = service.geographicToCartesian(u);

  print('ur.x: ' + ur.x.toString());
  print('ur.y: ' + ur.y.toString());
}