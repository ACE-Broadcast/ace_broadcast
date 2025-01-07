import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';

class SavedButton extends StatefulWidget {
  final bool isSaved;
  final void Function()? onTap;

  const SavedButton({
    super.key,
    required this.isSaved,
    required this.onTap,
  });

  @override
  State<SavedButton> createState() => _SavedButtonState();
}

class _SavedButtonState extends State<SavedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Set initial value based on isSaved
    if (widget.isSaved) {
      _controller.value = 1.0;
    } else {
      _controller.value = 0.0;
    }
    _isInitialized = true;
  }

  @override
  void didUpdateWidget(SavedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isInitialized) {
      _initializeController();
    }
    if (widget.isSaved != oldWidget.isSaved) {
      if (widget.isSaved) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox(
        width: 24,
        height: 24,
      );
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: SizedBox(
        width: 32,
        height: 24,
        child: OverflowBox(
          maxWidth: 40,
          maxHeight: 40,
          child: Lottie.asset(
            'assets/lottie/saved.json',
            controller: _controller,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}
