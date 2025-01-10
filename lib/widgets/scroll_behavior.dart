import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScrollToHideWidget extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final Duration duration;

  const ScrollToHideWidget({
    super.key,
    required this.child,
    required this.controller,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<ScrollToHideWidget> createState() => _ScrollToHideWidgetState();
}

class _ScrollToHideWidgetState extends State<ScrollToHideWidget> {
  bool isVisible = true;
  double lastOffset = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listen);
  }

  @override
  void dispose() {
    widget.controller.removeListener(listen);
    super.dispose();
  }

  void listen() {
    if (!mounted) return;

    final offset = widget.controller.offset;
    final direction = widget.controller.position.userScrollDirection;

    if (offset <= 0) {
      show();
    } else if (direction == ScrollDirection.reverse) {
      hide();
    } else if (direction == ScrollDirection.forward) {
      show();
    }

    lastOffset = offset;
  }

  void show() {
    if (!isVisible) setState(() => isVisible = true);
  }

  void hide() {
    if (isVisible) setState(() => isVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: widget.duration,
      height: isVisible ? 70 : 0,
      child: AnimatedOpacity(
        duration: widget.duration,
        opacity: isVisible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}
