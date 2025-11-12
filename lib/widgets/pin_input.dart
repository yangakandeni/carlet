import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carlet/widgets/animation_utils.dart';

/// Lightweight PIN input with external validation triggers (error/success).
/// Provides callbacks for unit testing & business logic separation.
class PinInput extends StatefulWidget {
  final int length;
  final void Function(String) onCompleted;
  final bool error; // externally set to trigger shake
  final bool success; // externally set to show success state

  const PinInput({super.key, this.length = 6, required this.onCompleted, this.error = false, this.success = false});

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textField = TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      maxLength: widget.length,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: 8, fontWeight: FontWeight.w700),
      decoration: InputDecoration(counterText: '', border: InputBorder.none, hintText: List.filled(widget.length, '•').join(' ')),
      onChanged: (v) {
        if (v.length == widget.length) {
          HapticFeedback.mediumImpact();
          widget.onCompleted(v);
        }
      },
    );

    return Column(
      children: [
        ShakeWidget(
          enabled: widget.error,
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: textField,
          ),
        ),
        if (widget.success)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Verified', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          )
      ],
    );
  }
}
