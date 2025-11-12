import 'package:flutter/material.dart';
import 'package:carlet/core/theme/app_components.dart';

/// Card with subtle scale on tap and optional onTap handler.
/// Safe to replace existing Card usages—keeps simple API (child + onTap).
class CarletCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const CarletCard({super.key, required this.child, this.onTap});

  @override
  State<CarletCard> createState() => _CarletCardState();
}

class _CarletCardState extends State<CarletCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 110), lowerBound: 0.0, upperBound: 0.02);
    _scale = Tween<double>(begin: 1.0, end: 0.99).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: Card(
          shape: const RoundedRectangleBorder(borderRadius: AppComponents.cardRadius),
          child: Padding(padding: const EdgeInsets.all(16), child: widget.child),
        ),
      ),
    );
  }
}
