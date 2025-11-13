import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carlet/utils/ui_constants.dart';

/// A minimal adaptive button with press-scale animation and haptic feedback.
/// Uses ElevatedButton / OutlinedButton based on isPrimary flag for compatibility.
class CarletButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool showLoading;
  final Widget? icon;
  final TextStyle? textStyle;

  /// Convenience constructor for primary button.
  const CarletButton.primary({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    bool showLoading = false,
    Widget? icon,
    TextStyle? textStyle,
  }) : this(
          key: key,
          text: text,
          onPressed: onPressed,
          isPrimary: true,
          showLoading: showLoading,
          icon: icon,
          textStyle: textStyle,
        );

  /// Convenience constructor for outlined button.
  const CarletButton.outlined({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    bool showLoading = false,
    Widget? icon,
    TextStyle? textStyle,
  }) : this(
          key: key,
          text: text,
          onPressed: onPressed,
          isPrimary: false,
          showLoading: showLoading,
          icon: icon,
          textStyle: textStyle,
        );

  const CarletButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.showLoading = false,
    this.icon,
    this.textStyle,
  });

  @override
  State<CarletButton> createState() => _CarletButtonState();
}

class _CarletButtonState extends State<CarletButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final defaultTextStyle = widget.textStyle ?? theme.textTheme.labelLarge?.copyWith(
      fontSize: UIConstants.kButtonLabelSize,
      fontWeight: FontWeight.w600,
      color: widget.isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
    );

    final Widget content = widget.showLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.onPrimary,
            ),
          )
        : (widget.icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTheme(
                    data: IconThemeData(
                      color: widget.isPrimary
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                    child: widget.icon!,
                  ),
                  const SizedBox(width: 8),
                  Text(widget.text, style: defaultTextStyle),
                ],
              )
            : Text(widget.text, style: widget.textStyle));

    final hoveredElevation = WidgetStateProperty.resolveWith<double?>((states) {
      if (states.contains(WidgetState.hovered)) return 3;
      return null; // defer to theme
    });

    // Enforce a consistent minimum height for CTAs across the app while
    // still allowing theme overrides to control color/shape.
    final buttonStyle = ButtonStyle(
      elevation: hoveredElevation,
  minimumSize: WidgetStateProperty.all(const Size.fromHeight(UIConstants.kButtonMinHeight)),
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 14, horizontal: 16)),
    );

    final button = widget.isPrimary
        ? ElevatedButton(
            onPressed: widget.showLoading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onPressed();
                  },
            style: buttonStyle,
            child: content,
          )
        : OutlinedButton(
            onPressed: widget.showLoading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onPressed();
                  },
            style: buttonStyle,
            child: content,
          );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, ch) => Transform.scale(scale: _scale.value, child: ch),
        child: button,
      ),
    );
  }
}
