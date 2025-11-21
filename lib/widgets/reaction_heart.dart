import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carlet/widgets/animation_utils.dart';

/// Reaction heart that pulses and triggers haptic feedback on toggle.
class ReactionHeart extends StatefulWidget {
  final bool initial;
  final void Function(bool) onChanged;
  final int count;

  const ReactionHeart({super.key, required this.initial, required this.onChanged, this.count = 0});

  @override
  State<ReactionHeart> createState() => _ReactionHeartState();
}

class _ReactionHeartState extends State<ReactionHeart> {
  late bool active;
  late int count;

  @override
  void initState() {
    super.initState();
    active = widget.initial;
    count = widget.count;
  }

  void _toggle() {
    setState(() {
      active = !active;
      count = active ? count + 1 : (count > 0 ? count - 1 : 0);
    });
    HapticFeedback.selectionClick();
    widget.onChanged(active);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Pulse(
            play: active,
            child: FaIcon(
              active ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
              size: 18,
              color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).iconTheme.color,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('$count', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
