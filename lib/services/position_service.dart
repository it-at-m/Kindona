import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:indoor_navigation/services/ble_service.dart';
import 'package:indoor_navigation/services/gps_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxdart/rxdart.dart';

class PositionService {

  static final BehaviorSubject<Pos> inject = BehaviorSubject<Pos>();

  static Stream<Pos> get observe => inject.stream;

  final GpsService gpsService = GpsService();
  final BleService bleService = BleService();

  Timer _t = Timer(const Duration(seconds: 0), () {});

  bool _bleActive = false;

  static List<Beacon> beaconSource = [
    Beacon('E4:E1:12:9A:49:C3', Pos(48.119074319288565, 11.531706669465034)),
    Beacon('E4:E1:12:9A:4A:04', Pos(48.11908247754796, 11.531673866862608)),
    Beacon('E4:E1:12:9A:4A:0F', Pos(48.119063676229175, 11.531631622074215)),
    Beacon('E4:E1:12:9B:0B:98', Pos(48.11903636953963, 11.531646374222545)),
    Beacon('E4:E1:12:9A:49:EB', Pos(48.11902306725213, 11.531682584041167))
  ];

  PositionService() {
    if (!kIsWeb) {
      bleService.setBeacons(beaconSource);
      GpsService.observe.listen(_newGpsPositon);
      BleService.observe.listen(_newBlePosition);
    }
  }

  void startPositioning() {
    if (!kIsWeb) {
      gpsService.startPositioning();
      bleService.startPositioning();
    }
  }

  void stopPositioning() {
    if (!kIsWeb) {
      gpsService.stopPositioning();
      bleService.stopPositioning();
    }
  }

  void setBeacons(List<Beacon> beacons) {
    bleService.setBeacons(beacons);
  }

  void _newGpsPositon(Position p) {
    if (!_bleActive) {
      inject.add(Pos(p.latitude, p.longitude));
    }
  }

  void _newBlePosition(Pos p) {
    inject.add(p);
    _resetTimer();
    _bleActive = true;
  }

  void _resetTimer() {
    _t.cancel();
    _t = Timer(const Duration(seconds: 20), () => _bleActive = false);
  }
}