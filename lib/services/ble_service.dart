import 'dart:async';
import 'dart:math';

import 'package:epitaph_ips/epitaph_ips/buildings/point.dart';
import 'package:epitaph_ips/epitaph_ips/positioning_system/real_beacon.dart' as epi;
import 'package:epitaph_ips/epitaph_ips/tracking/filter.dart';
import 'package:epitaph_ips/epitaph_ips/tracking/lma.dart';
import 'package:epitaph_ips/epitaph_ips/tracking/merwe_function.dart';
import 'package:epitaph_ips/epitaph_ips/tracking/sigma_point_function.dart';
import 'package:epitaph_ips/epitaph_ips/tracking/simple_ukf.dart';
import 'package:epitaph_ips/epitaph_ips/tracking/tracker.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:rxdart/rxdart.dart';
import 'package:epitaph_ips/epitaph_ips/positioning_system/beacon.dart' as epi;
import 'package:ml_linalg/linalg.dart';

class BleService {

  static final BehaviorSubject<Pos> positionStream = BehaviorSubject();

  static Stream<Pos> get observe => positionStream.stream;

  final Map<String, epi.Beacon> beacons = {
    'E4:E1:12:9A:49:C3': epi.RealBeacon('E4:E1:12:9A:49:C3', 'blukii', Point(0,0)),
    'E4:E1:12:9A:4A:03': epi.RealBeacon('E4:E1:12:9A:4A:03', 'blukii', Point(2.40,0)),
    'E4:E1:12:9A:4A:0F': epi.RealBeacon('E4:E1:12:9A:4A:0F', 'blukii', Point(3.90,2.35)),
    'E4:E1:12:9B:0B:98': epi.RealBeacon('E4:E1:12:9B:0B:98', 'blukii', Point(2.7,4.60)),
    'E4:E1:12:9A:49:EB': epi.RealBeacon('E4:E1:12:9A:49:EB', 'blukii', Point(0,4.6))
  };

  final Map<String, ReceivedBeacon> foundBeacons = {};

  late CoordinationSystemConverter _coords;

  Function? onLocationServicesDisabled;
  Function? onBluetoothDisabled;

  late Tracker _tracker;
  late LMA _lma;

  // Set the proximityUUID to the uuid of your iBeacons to prefilter
  // the discovered ble devices
  final Region region = Region(identifier: 'changememaybe' /*,proximityUUID: 'considerchangingme'*/);

  BleService({
    this.onLocationServicesDisabled,
    this.onBluetoothDisabled
  }) {
    //Initialize calculator
    _lma = LMA();

    //Very basic models for unscented Kalman filter
    Matrix fxUserLocation(Matrix x, double dt, List? args) {
      List<double> list = [
        x[1][0] * dt + x[0][0],
        x[1][0],
        x[3][0] * dt + x[2][0],
        x[3][0]
      ];
      return Matrix.fromFlattenedList(list, 4, 1);
    }

    Matrix hxUserLocation(Matrix x, List? args) {
      return Matrix.row([x[0][0], x[0][2]]);
    }

    //Sigma point function for unscented Kalman filter
    SigmaPointFunction sigmaPoints = MerweFunction(4, 0.1, 2.0, 1.0);

    //Initialize filter
    Filter filter = SimpleUKF(4, 2, 5, hxUserLocation, fxUserLocation, sigmaPoints, sigmaPoints.numberOfSigmaPoints());

    //Initialize tracker
    _tracker = Tracker(_lma, filter);
  }

  StreamSubscription<RangingResult>? rangingStream;
  void startPositioning() async {
    if (rangingStream != null) {
      return;
    }
    var locationEnabled = await flutterBeacon.checkLocationServicesIfEnabled;
    if (!locationEnabled) {
      onLocationServicesDisabled?.call();
      return;
    }

    var bluetoothState = await flutterBeacon.bluetoothState;
    if (bluetoothState != BluetoothState.stateOn) {
      onBluetoothDisabled?.call();
      return;
    }

    await Future.wait([
      flutterBeacon.initializeAndCheckScanning,
      flutterBeacon.setScanPeriod(1000),
      flutterBeacon.setBetweenScanPeriod(150)
    ]);

    rangingStream = flutterBeacon.ranging([region])
        .listen(_updateBeacon);
  }

  void stopPositioning() {
    if (rangingStream != null) {
      rangingStream!.cancel();
    }
  }

  void _updateBeacon(RangingResult result) {
    var updated = false;
    for (var beacon in result.beacons) {
      if (beacon.macAddress == null || !beacons.containsKey(beacon.macAddress!)) {
        continue;
      }
      foundBeacons.update(beacon.macAddress.toString(), (value) { value.rssiUpdate(beacon.rssi); value.reset(); return value;},
          ifAbsent: () => ReceivedBeacon(beacons[beacon.macAddress!]!, (b) => foundBeacons.remove(b.beacon.id)));
      updated = true;
    }

    if (updated) {
      if (foundBeacons.length >= 3) {
        var beaconList = foundBeacons.entries.map((k) => k.value.beacon).toList();
        beaconList.sort((l, r) => l.id.compareTo(r.id));
        _lma.reset();
        var point = _lma.calculate(beaconList);
        positionStream.add(convertToPosition(point));
      }
    }
  }

  Pos convertToPosition(Point p) {
    return _coords.cartesianToGeographic(p);
  }

  ///
  /// Sets the list of known beacons and builds the cartesian coordinate system.
  ///
  void setBeacons(List<Beacon> beacons) {
    assert(beacons.length >= 3);

    _coords = CoordinationSystemConverter(beacons[0].position);

    this.beacons.clear();
    var beacon = beacons[0];
    var b = epi.RealBeacon(beacon.id, beacon.id, Point(0, 0, beacon.position.altitude));
    this.beacons[beacon.id] = b;
    for (var beacon in beacons.skip(1)) {
      var p = _coords.geographicToCartesian(beacon.position);
      b = epi.RealBeacon(beacon.id, beacon.id, p);
      this.beacons[beacon.id] = b;
    }

  }
}

class UserPosition {
  final double lat;
  final double lon;

  UserPosition(this.lat, this.lon);
}

class Beacon {
  String id;
  Pos position;
  Beacon(this.id, this.position);
}

class Pos implements ILatLong {
  final double lat;
  final double lon;
  double altitude;
  Pos(this.lat, this.lon, {this.altitude = 0});

  @override
  get latitude => lat;
  @override
  get longitude => lon;

  factory Pos.fromPosition(Position p) {
    return Pos(p.latitude, p.longitude);
  }
}

class ReceivedBeacon {
  final epi.Beacon beacon;
  final void Function(ReceivedBeacon) onTimeout;
  late Timer timer;

  ReceivedBeacon(this.beacon, this.onTimeout) {
    timer = Timer(const Duration(seconds: 0), () {});
    reset();
  }

  void rssiUpdate(int rssi) {
    beacon.rssiUpdate(rssi);
  }
  void reset() {
    stop();
    timer = Timer(const Duration(seconds: 30), () => onTimeout(this));
  }
  void stop() {
    timer.cancel();
  }
}

class CoordinationSystemConverter {
  final Pos origin;

  CoordinationSystemConverter(this.origin);

  Pos get gRef {
    return Pos(origin.lat + 0.0001, origin.lon + 0.0001);
  }

  Point get cRef {
    return geographicToCartesian(gRef);
  }

  ///
  /// Translates a point of the cartesian coordinate system back
  /// into a geographic system (WGS84). Naive solution with a accuracy of
  /// 0.1% is good enough for indoor navigation. (on 100 meters distance to
  /// the reference point with an error of 10 centimeters)
  /// for indoor distances.
  /// Uses the geo coordinate for the point (0,0) and a second point described
  /// with a cartesian and geo coordinate as reference.
  ///
  Pos cartesianToGeographic(Point p) {

    var latdfac = p.x / cRef.x;
    var lat_delta = (origin.lat - gRef.lat) * latdfac;
    var londfac = p.y / cRef.y  ;
    var lon_delta = (origin.lon - gRef.lon) * londfac;

    var userPos = Pos(origin.lat + lon_delta, origin.lon + lat_delta, altitude: p.z);

    return userPos;
  }

  Point geographicToCartesian(Pos p) {

    double dOnLat = distance(origin, Pos(origin.lat, p.lon));
    double dOnLon = distance(origin, Pos(p.lat, origin.lon));

    return Point(dOnLat, dOnLon, p.altitude);
  }

  ///
  /// Calculates distance between two coordinates (WGS84) in meters
  /// with the help of Vincenty's formulae
  /// https://en.wikipedia.org/wiki/Vincenty%27s_formulae
  ///
  double distance(Pos p1, Pos p2) {
    // length of semi-major axis of the ellipsoid (radius at equator in meters); (WGS-84)
    var a = 6378137.0;
    // flattening of the ellipsoid (WGS-84)
    var f = 1/298.257223563;
    // length of semi-minor axis of the ellipsoid (radius at the poles); b = (1 − ƒ) a
    var b = 6356752.314245;

    // Latitude in radians
    var phi_1 = (pi/180) * p1.lat;
    var phi_2 = (pi/180) * p2.lat;

    // reduced latitude (latitude on the auxiliary sphere)
    var u1 = atan((1-f)*tan(phi_1));
    var u2 = atan((1-f)*tan(phi_2));

    // Longitude in radians
    var l1 = (pi/180) * p1.lon;
    var l2 = (pi/180) * p2.lon;

    var L = l2 - l1;

    var lambda = L;

    num cos_alpha_squared = 0,
        sigma = 0,
        sin_sigma = 0,
        cos_2_sigma_m = 0,
        cos_sigma= 0
    ;
    for (int i = 0; i < 10; i++) {
      sin_sigma = sqrt(pow(cos(u2) * sin(lambda), 2) +
          pow(cos(u1) * sin(u2) - sin(u1) * cos(u2) * cos(lambda), 2));

      cos_sigma = sin(u1) * sin(u2) + cos(u1) * cos(u2) * cos(lambda);

      sigma = atan2(sin_sigma, cos_sigma);

      var sin_alpha = (cos(u1) * cos(u2) * sin(lambda)) / sin_sigma;

      cos_alpha_squared = (1 - pow(sin_alpha, 2));

      cos_2_sigma_m = cos(sigma) -
          ((2 * sin(u1) * sin(u2)) / cos_alpha_squared);

      var C = (f / 16) * cos_alpha_squared *
          (4 + (f * (4 - (3 * cos_alpha_squared))));

      lambda = L + (1 - C) * f * sin_alpha * (sigma + C * sin_sigma *
          (cos_2_sigma_m + C * cos_sigma * (-1 + 2 * pow(cos_2_sigma_m, 2))));
    }

    var u_squared = cos_alpha_squared * ((pow(a,2)-pow(b,2))/pow(b,2));

    var A = 1 + (u_squared / 16384) * (4096 + u_squared * (-768 + u_squared + (320 - (175 * u_squared))));

    var B = (u_squared / 1024) * (256 + u_squared * (-128+ u_squared * (74 - (47 * u_squared))));

    var delta_sigma = B * sin_sigma * (cos_2_sigma_m + (0.25 * B * (cos_sigma*(-1+2*pow(cos_2_sigma_m, 2))-((B/6)*cos_2_sigma_m*(-3+4*pow(sin_sigma, 2))*(-3+4*pow(cos_2_sigma_m, 2))))));

    var s = b * A * (sigma-delta_sigma);

    /* dead code for azimuth calculation currently not needed, but who knows, might come handy in the future
    var alpha_1 = atan2(cos(u2)*sin(lambda), cos(u1)*sin(u2)-sin(u1)*cos(u2)*cos(lambda));
    var alpha_2 = atan2(cos(u1)*sin(lambda), -sin(u1)*cos(u2)+cos(u1)*sin(u2)*cos(lambda));
    */
    return s;
  }
}