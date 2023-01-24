import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:indoor_navigation/navigation/navigation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:indoor_navigation/context/map_context.dart';
import 'package:indoor_navigation/services/selectedroute.dart';
import 'package:indoor_navigation/util/FakeRoute.dart';

import '../util/room_util.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<StatefulWidget> createState() => _TopBarState();

}

class _TopBarState extends State<TopBar> with TickerProviderStateMixin {

  Room? from;
  Room? to;

  late AnimationController _appBarController;
  late AnimationController _routeController;
  late AnimationController _searchController;
  late Animation<Offset> _animation;
  late Animation<double> _overlayAnimation;
  late Animation<double> _searchOverlayAnimation;

  StreamSubscription? navigateToStream;

  @override
  void initState() {
    super.initState();

    _appBarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    _routeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _appBarController,
      curve: Curves.easeOutCubic,
    ));
    _overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _routeController,
      curve: Curves.easeInCubic,
    ));
    _searchOverlayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _navigateToRoomRequest(Room room) {
    to = room;
    transition(BarOverlayState.routeOverlay);
  }

  @override
  void dispose() {
    _appBarController.dispose();
    _routeController.dispose();
    _searchController.dispose();
    navigateToStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    navigateToStream ??= MapContext.of(context).navigateToStream.listen(_navigateToRoomRequest);
    var widgets = <Widget>[
      SizedBox(
          height: 80,
          child: Builder(
              builder: (context) => SlideTransition(position: _animation,
                  transformHitTests: true,
                  child: AppBar(
                    title: Text(AppLocalizations.of(context)!.apptitle),
                    actions: [
                      IconButton(
                          onPressed: () => transition(BarOverlayState.searchOverlay),
                          icon: const Icon(Icons.search)
                      ),
                    ],
                  )
              )
          )
      )
    ];

    if (_routeController.status != AnimationStatus.dismissed) {
      widgets.add(_createOverlay(context));
    }
    if (_searchController.status != AnimationStatus.dismissed) {
      widgets.add(_createSearchOverlay(context));
    }
    return Stack(children: widgets,);
  }

  BarOverlayState currentState = BarOverlayState.appBar;
  transition(BarOverlayState targetState) {
    switch (currentState) {
      case BarOverlayState.appBar:
        _removeAppBar();
        break;
      case BarOverlayState.routeOverlay:
        _removeRouteOverlay();
        break;
      case BarOverlayState.searchOverlay:
        _removeSearchOverlay();
        break;
    }
    switch (targetState) {
      case BarOverlayState.appBar:
        _showAppBar();
        break;
      case BarOverlayState.routeOverlay:
        _showRouteOverlay();
        break;
      case BarOverlayState.searchOverlay:
        _showSearchOverlay();
        break;
    }
  }

  FakeRoute? fakeRoute;
  _showSearchOverlay() {
    _searchController.forward().then((_) => setState(() => {}));
    if (fakeRoute != null) {
      Navigator.of(context).removeRoute(fakeRoute!);
      fakeRoute = null;
    }
    fakeRoute = FakeRoute(onPop: () => transition(BarOverlayState.appBar));
    Navigator.of(context).push(fakeRoute!);
    currentState = BarOverlayState.searchOverlay;
  }

  _removeSearchOverlay() {
    _searchController.reverse();
  }

  _showRouteOverlay() {
    _routeController.forward().then((_) => setState(() => {}));
    setState(() => {});
    if (fakeRoute != null) {
      Navigator.of(context).removeRoute(fakeRoute!);
      fakeRoute = null;
    }
    fakeRoute = FakeRoute(onPop: () => transition(BarOverlayState.appBar));
    Navigator.of(context).push(fakeRoute!);
    currentState = BarOverlayState.routeOverlay;
  }

  _removeRouteOverlay() {
    _routeController.reverse();
  }

  _showAppBar() {
    _appBarController.forward().then((_) => setState(() => {}));
    currentState = BarOverlayState.appBar;
  }

  _removeAppBar() {
    _appBarController.reverse();
  }

  Widget _createSearchOverlay(BuildContext context) {
    var margin = const EdgeInsets.fromLTRB(10, 10, 10, 10);
    return Positioned(
        top: MediaQuery.of(context).viewPadding.top + (Theme.of(context).appBarTheme.toolbarHeight?? 0),
        child: FadeTransition(
            opacity: _searchOverlayAnimation,
            child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height,
                  maxWidth: MediaQuery.of(context).size.width-margin.horizontal,
                ),
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    color: Theme.of(context).canvasColor,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor,
                        blurRadius: 0.5,
                      ),
                    ]
                ),
                margin: margin,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(flex: 1, child: IconButton(
                                onPressed: () => transition(BarOverlayState.appBar),
                                icon: const Icon(Icons.arrow_back)
                            )),
                            Expanded(
                              flex: 9,
                              child: _buildDropdown(context,
                                  icon: const Icon(Icons.search_outlined),
                                  initial: from,
                                  hint: AppLocalizations.of(context)!.search,
                                  onChanged: _moveToRoom,
                            ))]),
                    ])
            )
        )
    );
  }

  _moveToRoom(Room? room) {
    if (room == null) return;
    var viewModel = MapContext.of(context).viewModel;
    viewModel.setIndoorLevel(room.level);
    viewModel.setMapViewPosition(room.latLong.latitude, room.latLong.longitude);
    if (viewModel.mapViewPosition!.zoomLevel < 18) {
      viewModel.setZoomLevel(18);
    }
    MapContext.of(context).roomStream.value = room;
  }

  Widget _createOverlay(BuildContext context) {
    var margin = const EdgeInsets.fromLTRB(10, 10, 10, 10);
    return Positioned(
        top: MediaQuery.of(context).viewPadding.top + (Theme.of(context).appBarTheme.toolbarHeight?? 0),
        child: FadeTransition(
            opacity: _overlayAnimation,
            child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height,
                  maxWidth: MediaQuery.of(context).size.width-margin.horizontal,
                ),
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    color: Theme.of(context).canvasColor,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor,
                        blurRadius: 0.5,
                      ),
                    ]
                ),
                margin: margin,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(flex: 1, child: IconButton(
                                onPressed: () => transition(BarOverlayState.appBar),
                                icon: const Icon(Icons.arrow_back)
                            )),
                            Expanded(
                              flex: 9,
                              child: _buildDropdown(context,
                                  icon: const Icon(Icons.circle_outlined),
                                  initial: from,
                                  hint: AppLocalizations.of(context)!.navigationstart,
                                  onChanged: _setFrom),
                            )]),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          Expanded(flex: 1, child: Container(),),
                          Expanded(flex: 9, child:
                          _buildDropdown(context,
                              icon: const Icon(Icons.location_on_outlined),
                              initial: to,
                              hint: AppLocalizations.of(context)!.navigationtarget,
                              onChanged: _setTo),
                          )],
                      )
                    ]
                )
            )

        ));
  }

  Widget _buildDropdown(BuildContext context, {
    required String hint,
    required  Icon icon,
    Room? initial,
    required  void Function(Room?) onChanged}) {
    String initialEdit = "";
    if (initial != null) {
      initialEdit = roomLabel(context, initial);
    }
    return  Container(
        padding: const EdgeInsets.all(5),
        child: Autocomplete<Object>(
          initialValue: TextEditingValue(text: initialEdit),
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) => TextFormField(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: hint,
              suffixIcon: icon,
              contentPadding: const EdgeInsets.only(left: 10.0),
            ),
            controller: textEditingController,
            focusNode: focusNode,
            onFieldSubmitted: (text) => onFieldSubmitted(),
          ),
          optionsBuilder: (filter) {
            Iterable<Object> rooms = MapContext.of(context).rooms.where((room) => roomLabel(context, room).contains(filter.text.replaceAll(r"\s+", "")));
            if (filter.text.isEmpty) {
              rooms = <Object>["Your Position"].followedBy(rooms);
            }
            return rooms;
          },
          displayStringForOption: (room) => room is Room ? roomLabel(context, room) : room.toString(),
          onSelected: (val) {  if (val is Room) onChanged(val); },
          optionsViewBuilder: (context, onSelected, options) => _autoCompleteOption(context, onSelected, options),
        ));
  }

  Widget _autoCompleteOption(BuildContext context, onSelected, Iterable<Object> options) {
    return Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 200.0,
            ),
            child:  ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (BuildContext context, int index) {
                final option = options.elementAt(index);
                return ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: double.infinity,
                    ),
                    child: InkWell(
                      onTap: () {
                        onSelected(option);
                      },
                      child: Builder(
                          builder: (BuildContext context) {
                            final bool highlight = AutocompleteHighlightedOption.of(context) == index;
                            if (highlight) {
                              SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
                                Scrollable.ensureVisible(context, alignment: 0.5);
                              });
                            }
                            return Container(
                              color: highlight ? Theme.of(context).focusColor : null,
                              padding: const EdgeInsets.all(16.0),
                              child: Row(children: [
                                Icon(option is IndoorNode ? getRoomIcon(option) : Icons.my_location),
                                option is Room ? Text(roomLabel(context, option))
                                  : Text(option.toString())
                              ]),
                            );
                          }
                      ),
                    ));
              },
            ),
          ),
        )
    );
  }

  String roomLabel(BuildContext context, Room room) {
    return "${(room).name} (${AppLocalizations.of(context)!.floor} ${room.level})";
  }

  void _setFrom(Room? room) {
    from = room;
    _updateSelectedRoute();
  }

  void _setTo(Room? room) {
    to = room;
    _updateSelectedRoute();
  }

  void _updateSelectedRoute() {
    if (from != null && to != null) {
      SelectedRoute.routeStream.add([from!, to!]);
    }
  }
}

enum BarOverlayState {
  appBar,
  routeOverlay,
  searchOverlay,
}