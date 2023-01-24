import 'dart:math';

import 'package:flutter/material.dart';

typedef OnChange = void Function(int level);

/// Statefull Widget to display a level bar
/// requires a BehaviourSubject of type int for the current indoor level
/// requires a map of levels with an optional level code string
/// The map will be automatically ordered from high to low
class IndoorLevelBar extends StatefulWidget {
  final Map<int, String?> indoorLevels;
  final double width;
  final double itemHeight;
  final int maxVisibleItems;
  final Color? fillColor;
  final Color? activeColor;
  final double elevation;
  final BorderRadius borderRadius;
  final OnChange onChange;
  final int initialLevel;

  const IndoorLevelBar({
    Key? key,
    required this.indoorLevels,
    required this.onChange,
    this.width = 30,
    this.itemHeight = 48,
    this.maxVisibleItems  = 5,
    this.fillColor,
    this.activeColor,
    this.elevation = 2,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.initialLevel = 0,
  }) : super(key: key);

  @override
  IndoorLevelBarState createState() => IndoorLevelBarState();
}

/////////////////////////////////////////////////////////////////////////////
class IndoorLevelBarState extends State<IndoorLevelBar> {
  ScrollController? _scrollController;

  final ValueNotifier<bool> _onTop = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _onBottom = ValueNotifier<bool>(false);

  late int _level;

  int shownItems = 0;

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
    setLevel(_level, publish: false);
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _onTop.dispose();
    _onBottom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // widget
    return Material(
      elevation: widget.elevation,
      borderRadius: widget.borderRadius,
      clipBehavior: Clip.antiAlias,
      color: widget.fillColor?? Theme.of(context).buttonTheme.colorScheme!.background,
      child: LayoutBuilder(
        // will also be called on device orientation change
          builder: (context, constraints) {
            // get the total number of levels
            int totalIndoorLevels = widget.indoorLevels.length;
            var indoorLevels = widget.indoorLevels.keys.toList()..sort();
            double maxHeight = min(
                constraints.maxHeight, widget.maxVisibleItems * widget.itemHeight);
            // calculate nearest multiple item height
            shownItems = (maxHeight / widget.itemHeight).floor();
            maxHeight = shownItems * widget.itemHeight;
            // check if level bar will be scrollable
            bool isScrollable = maxHeight < totalIndoorLevels * widget.itemHeight;

            // if level bar will be scrollable
            if (isScrollable) {
              _scrollController ??=
                  ScrollController(initialScrollOffset: 0);
            }

            return ConstrainedBox(
              constraints: BoxConstraints(
                // set to nearest multiple item height
                maxHeight: maxHeight,
                maxWidth: widget.width,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Visibility(
                    // toggle on if level bar will be scrollable
                    visible: isScrollable,
                    child: ValueListenableBuilder(
                      valueListenable: _onTop,
                      builder: (BuildContext context, bool onTop, Widget? child) {
                        return MaterialButton(
                            shape: const ContinuousRectangleBorder(),
                            height: widget.itemHeight,
                            onPressed: onTop ? null : scrollLevelUp,
                            visualDensity: VisualDensity.compact,
                            child: const Icon(Icons.keyboard_arrow_up_rounded));
                      },
                    ),
                  ),
                  Flexible(
                    child: NotificationListener<ScrollNotification>(
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        reverse: true,
                        itemCount: totalIndoorLevels,
                        itemExtent: widget.itemHeight,
                        padding: const EdgeInsets.all(0),
                        itemBuilder: (context, i) {
                          // get item indoor level from index
                          int itemIndoorLevel = indoorLevels[i];
                          // widget
                          return MaterialButton(
                            shape: const ContinuousRectangleBorder(),
                            color: _level == itemIndoorLevel
                                ? (widget.activeColor?? Theme.of(context).buttonTheme.colorScheme!.primary)
                                : null,
                            textColor: _level == itemIndoorLevel ? Theme.of(context).buttonTheme.colorScheme!.onPrimary : null,
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              // do nothing if already selected
                              if (_level != itemIndoorLevel) {
                                setLevel(itemIndoorLevel);
                              }
                            },
                            child: Text(
                              // show level code if available
                              widget.indoorLevels[itemIndoorLevel] ??
                                  itemIndoorLevel.toString(),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Visibility(
                    // toggle on if level bar will be scrollable
                    visible: isScrollable,
                    child: ValueListenableBuilder(
                      valueListenable: _onBottom,
                      builder:
                          (BuildContext context, bool onBottom, Widget? child) {
                        return MaterialButton(
                          shape: const ContinuousRectangleBorder(),
                          height: widget.itemHeight,
                          onPressed: onBottom ? null : scrollLevelDown,
                          visualDensity: VisualDensity.compact,
                          child: const Icon(Icons.keyboard_arrow_down_rounded),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }

  void setLevel(int level, {bool publish = true}) {
    if (mounted) {
      setState(() => _level = level);
    }
    if (publish) {
      widget.onChange(_level);
    }
    _onTop.value = getKeyIndex(_level) == widget.indoorLevels.length-1;
    _onBottom.value = getKeyIndex(_level) == 0;
    if (_scrollController == null) return;
    double itemHeight = widget.itemHeight;
    double nextPosition = itemHeight * getKeyIndex(_level) - itemHeight;
    var offsetDiff = nextPosition - _scrollController!.offset;
    if (offsetDiff < (itemHeight*(shownItems/2.0).floor()) ||  offsetDiff > widget.itemHeight * (widget.maxVisibleItems-2-(shownItems/2.0).ceil())) {
      _scrollController!.animateTo(
        nextPosition,
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void scrollLevelUp() {
    setLevel(_levelKeys()[min(widget.indoorLevels.length-1, getKeyIndex(_level)+1)]);
  }

  void scrollLevelDown() {
    setLevel(_levelKeys()[max(0, getKeyIndex(_level)-1)]);
    if (_scrollController == null) return;
  }

  int getKeyIndex(int key) {
    return _levelKeys().indexOf(key);
  }

  List<int> _levelKeys() {
    return  widget.indoorLevels.keys.toList()
      ..sort();
  }
}