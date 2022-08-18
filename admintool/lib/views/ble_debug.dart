import 'package:flutter/material.dart';

import '../services/ble_service.dart';

class BleDebugWidget extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _BleDebugWidgetState();
}

class _BleDebugWidgetState extends State<BleDebugWidget> with WidgetsBindingObserver  {

  final BleService service = BleService(
  );

  Pos? _pos;

  static List<Beacon> beaconSource = [
    Beacon('E4:E1:12:9A:49:C3', Pos(48.119074319288565, 11.531706669465034)),
    Beacon('E4:E1:12:9A:4A:03', Pos(48.11908247754796, 11.531673866862608)),
    Beacon('E4:E1:12:9A:4A:0F', Pos(48.119063676229175, 11.531631622074215)),
    Beacon('E4:E1:12:9B:0B:98', Pos(48.11903636953963, 11.531646374222545)),
    Beacon('E4:E1:12:9A:49:EB', Pos(48.11902306725213, 11.531682584041167))
  ];

  _BleDebugWidgetState() {
    BleService.observe.listen((value) => setState(() => _pos = value));
    service.setBeacons(beaconSource);
  }

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    service.startPositioning();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("Lifecycle: ");
    print(state.toString());
    switch (state) {
      case AppLifecycleState.resumed: {
        service.startPositioning();
        break;
      }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.paused: {
        service.stopPositioning();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    service.stopPositioning();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      MaterialButton(
          onPressed: () => setState(() {}), child: const Text('Refresh')),
      _pos != null
          ? Text('lat: ${_pos!.lat.toString()} lon: ${_pos!.lon.toString()}')
          : const Text('Keine Messung')
    ];

    for (var b in service.foundBeacons.values) {
      children.add(ListTile(
        key: Key(b.beacon.id),
        title: Text(b.beacon.id),
        trailing: Text(b.beacon.rssi.toString()),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stop the count!'),
      ),
      body: Container(
        child: ListView(
          children: children,
        ),
      ),
      drawer: Drawer(
          child: Column(
            children: [
              const Text('Navigation'),
              ListTile(
                title: const Text('Home'),
                onTap: () => Navigator.pushNamed(context, '/'),
              ),
              ListTile(
                title: const Text('Debug'),
                onTap: () => Navigator.pushNamed(context, '/debug'),
              )
            ],
          )
      ),
    );
  }
}