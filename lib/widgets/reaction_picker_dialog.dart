import 'package:flutter/material.dart';

import 'package:carlet/models/comment_model.dart';

class ReactionPickerDialog extends StatelessWidget {
  final Comment comment;
  final String? currentUserId;
  final Function(CommentReaction) onReactionSelected;

  const ReactionPickerDialog({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.onReactionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentReaction = currentUserId != null
        ? comment.reactions[currentUserId]
        : null;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'React to comment',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: CommentReaction.values.map((reaction) {
                final isSelected = currentReaction == reaction.emoji;
                return InkWell(
                  onTap: () {
                    onReactionSelected(reaction);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(40),
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        reaction.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
