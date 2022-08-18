import 'dart:async';

import 'package:admintool/services/ble_service.dart';
import 'package:admintool/services/gps_service.dart';
import 'package:admintool/views/ble_debug.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxdart/rxdart.dart';

class PositionService {

  static final Subject<Pos> _inject = BehaviorSubject<Pos>();

  static Stream<Pos> get observe => _inject.stream;

  final GpsService gpsService = GpsService();
  final BleService bleService = BleService();

  Timer _t = Timer(const Duration(seconds: 0), () {});

  bool _bleActive = false;

  static List<Beacon> beaconSource = [
    Beacon('E4:E1:12:9A:49:C3', Pos(48.119074319288565, 11.531706669465034)),
    Beacon('E4:E1:12:9A:4A:03', Pos(48.11908247754796, 11.531673866862608)),
    Beacon('E4:E1:12:9A:4A:0F', Pos(48.119063676229175, 11.531631622074215)),
    Beacon('E4:E1:12:9B:0B:98', Pos(48.11903636953963, 11.531646374222545)),
    Beacon('E4:E1:12:9A:49:EB', Pos(48.11902306725213, 11.531682584041167))
  ];

  PositionService() {
    bleService.setBeacons(beaconSource);
    GpsService.observe.listen(_newGpsPositon);
    BleService.observe.listen(_newBlePosition);
  }

  void startPositioning() {
    gpsService.startPositioning();
    bleService.startPositioning();
  }

  void stopPositioning() {
    gpsService.stopPositioning();
    bleService.stopPositioning();
  }

  void _newGpsPositon(Position p) {
    if (!_bleActive) {
      _inject.add(Pos(p.latitude, p.longitude));
      print('publish gps position');
    }
  }

  void _newBlePosition(Pos p) {
    _inject.add(p);
    _resetTimer();
    _bleActive = true;
    print('publish ble position');
  }

  void _resetTimer() {
    _t.cancel();
    _t = Timer(const Duration(seconds: 20), () => _bleActive = false);
  }
}