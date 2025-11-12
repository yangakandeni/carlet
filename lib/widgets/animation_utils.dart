import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Small reusable animation helpers used by widgets.
/// 1) Simple shake animation wrapper.
/// 2) Pulse animation wrapper for reaction icons.
/// Keep generic so other widgets can reuse. Lightweight and non-blocking.
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool enabled; // when true, plays once

  const ShakeWidget({super.key, required this.child, this.duration = const Duration(milliseconds: 500), this.enabled = false});

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    if (widget.enabled) _play();
  }

  void _play() {
    _ctrl
      ..reset()
      ..forward();
  }

  @override
  void didUpdateWidget(covariant ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _play();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Translate along X using a sine wave. 3 full shakes.
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value; // 0..1
        final shakes = 3;
        final amplitude = 8.0;
        final offsetX = math.sin(t * 2 * math.pi * shakes) * amplitude * (1 - t); // dampen towards end
        return Transform.translate(offset: Offset(offsetX, 0), child: child);
      },
      child: widget.child,
    );
  }
}

class Pulse extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool play; // when true, play one pulse

  const Pulse({super.key, required this.child, this.duration = const Duration(milliseconds: 250), this.play = false});

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    if (widget.play) _trigger();
  }

  void _trigger() {
    _ctrl
      ..reset()
      ..forward().then((_) => _ctrl.reverse());
  }

  @override
  void didUpdateWidget(covariant Pulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      _trigger();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    );
  }
}
