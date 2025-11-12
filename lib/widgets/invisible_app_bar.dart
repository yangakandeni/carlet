import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A small wrapper to produce a transparent, "invisible" AppBar while
/// preserving title/leading/actions and setting an appropriate
/// SystemUiOverlayStyle based on the current theme.
class InvisibleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double? leadingWidth;
  final PreferredSizeWidget? bottom;

  const InvisibleAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.leadingWidth,
    this.bottom,
  });

  @override
  Size get preferredSize => bottom?.preferredSize ?? const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final overlay = brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      leadingWidth: leadingWidth,
      bottom: bottom,
      // Ensure status bar icons are readable when AppBar is transparent
      systemOverlayStyle: overlay,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    );
  }
}
