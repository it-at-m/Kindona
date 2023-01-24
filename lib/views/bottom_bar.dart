import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:indoor_navigation/context/map_context.dart';
import 'package:indoor_navigation/navigation/navigation.dart';
import 'package:indoor_navigation/util/FakeRoute.dart';

import '../util/room_util.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<StatefulWidget> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> with SingleTickerProviderStateMixin {

  Room? room;
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    super.dispose();
    listenerReg?.cancel();
  }

  bool closed = true;

  StreamSubscription<Room?>? listenerReg;

  @override
  Widget build(BuildContext context) {
    listenerReg ??= MapContext
        .of(context)
        .observeSelectedRoom
        .listen((event) => _setRoom(event));

    var widgets = <Widget>[
      MaterialButton(
        onPressed: room == null ? null :
            () => closed ? _openBar() : _closeBar(),
        child: Divider(
          color: room != null ? Theme.of(context).textTheme.headline1!.color : null,
          thickness: 2,
        ),
      ),
    ];

    var roomName = room?.name;
    if (roomName == null || roomName.isEmpty) {
      if (room?.type == RoomType.toilet) {
        roomName = AppLocalizations.of(context)!.publictoilet;
      } else if (room?.type == RoomType.toiletMale) {
        roomName = AppLocalizations.of(context)!.publictoiletmale;
      }
      if (room?.type == RoomType.toiletFemale) {
        roomName = AppLocalizations.of(context)!.publictoiletfemale;
      }
    }

    widgets.add(
        Column(
            children: [
              Row(
                  children: [
                    Icon(room != null ? getRoomIcon(room!) : Icons.accessibility_new, size: Theme.of(context).textTheme.headlineMedium!.height),
                    Text("$roomName (${room?.level})",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ]
              ),
              ButtonBar(
                alignment: MainAxisAlignment.start,
                children: [
                  MaterialButton(
                    shape: const StadiumBorder(),
                    onPressed: () => MapContext.of(context).navigateToStream.value = room!,
                    color: Theme.of(context).primaryColor,
                    child: Row(
                        children: const [
                          Icon(Icons.navigation_outlined, size: 14),
                          Text("Route")]
                    ),
                  )
                ],
              )
            ]

        )
    );


    var column = Column(
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );

    return Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 10,
        right: 10,
        child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy > 0) {
                _closeBar();
              }
            },
            child: SlideTransition(
                position: _animation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    color: Theme.of(context).cardColor,
                    boxShadow: const [BoxShadow()],
                  ),
                  child: column,

                )
            )
        )
    );
  }

  _setRoom(Room? newRoom) {
    if (newRoom == null) {
      _closeBar();
      return;
    }
    if (newRoom == room) {
      _closeBar();
      return;
    }
    room = newRoom;
    _openBar();
  }

  FakeRoute? fakeRoute;
  _openBar() {
    setState(() => closed = false);
    if (fakeRoute != null) {
      Navigator.of(context).removeRoute(fakeRoute!);
    }
    fakeRoute = FakeRoute(onPop: () => _closeBar());
    Navigator.of(context).push(fakeRoute!);
    _controller.forward();
  }

  Future<void> _closeBar() {
    setState(() => closed = true);
    return _controller.reverse().then((_) => room = null);
  }

}