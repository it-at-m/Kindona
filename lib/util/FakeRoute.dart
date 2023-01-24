import 'package:flutter/cupertino.dart';

class FakeRoute extends Route<void> {
  final void Function() onPop;

  final Widget Function(BuildContext)? builder;
  FakeRoute({
    required this.onPop,
    this.builder,
    super.settings,
  }) {
    super.popped.then((t) => onPop());
  }

  final List<OverlayEntry> _overlayEntries = [];
  @override
  List<OverlayEntry> get overlayEntries => _overlayEntries;

  @override
  void install() {
    overlayEntries.add(
        OverlayEntry(builder: builder ?? (ctx) => Positioned(child: Container()))
    );
    super.install();
  }


}