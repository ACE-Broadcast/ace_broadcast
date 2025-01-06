import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';

class LikeButton extends StatefulWidget {
  final bool isLiked;
  final void Function()? onTap;

  const LikeButton({
    super.key,
    required this.isLiked,
    required this.onTap,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
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
      duration: const Duration(milliseconds: 500),
    );

    // Set initial value based on isLiked
    if (widget.isLiked) {
      _controller.value = 1.0;
    } else {
      _controller.value = 0.0;
    }
    _isInitialized = true;
  }

  @override
  void didUpdateWidget(LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isInitialized) {
      _initializeController();
    }
    if (widget.isLiked != oldWidget.isLiked) {
      if (widget.isLiked) {
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
          maxWidth: 140,
          maxHeight: 122,
          child: Lottie.asset(
            'assets/lottie/like.json',
            controller: _controller,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}
