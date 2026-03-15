import 'package:flutter/material.dart';

class BreathingCircle extends StatefulWidget {
  const BreathingCircle({super.key});

  @override
  State<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<BreathingCircle>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(
        width: 120 + (60 * _controller.value),
        height: 120 + (60 * _controller.value),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF4ADE80).withOpacity(0.2),
          border: Border.all(
            color: const Color(0xFF4ADE80).withOpacity(0.4),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            _controller.status == AnimationStatus.forward
                ? "Inhale"
                : "Exhale",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
