import 'package:flutter/material.dart';

import 'package:carlet/models/report_model.dart';
import 'package:carlet/widgets/carlet_badge.dart';
import 'package:carlet/widgets/carlet_card.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback? onResolve;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  const ReportCard({
    super.key,
    required this.report,
    this.onResolve,
    this.onLike,
    this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String? deletionHint() {
      if (report.status != 'resolved' || report.expireAt == null) return null;
      final now = DateTime.now().toUtc();
      final diff = report.expireAt!.toUtc().difference(now);
      if (diff.inSeconds <= 0) return 'Will be deleted soon';
      if (diff.inMinutes < 1) return 'Will be deleted in <1m';
      if (diff.inMinutes < 60) return 'Will be deleted in ${diff.inMinutes}m';
      final hours = diff.inHours;
      return 'Will be deleted in ${hours}h';
    }

    // Status badge colors
    final isOpen = report.status == 'open';
    final badgeColor = isOpen 
        ? theme.colorScheme.error.withValues(alpha: 0.12)
        : theme.colorScheme.secondaryContainer;
    final badgeTextColor = isOpen 
        ? theme.colorScheme.error 
        : theme.colorScheme.onSecondaryContainer;

    return CarletCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.photoUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(report.photoUrl!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (report.licensePlate != null &&
                  report.licensePlate!.isNotEmpty)
                CarletBadge(
                  text: report.licensePlate!,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  textColor: theme.colorScheme.onPrimaryContainer,
                ),
              const Spacer(),
              CarletBadge(
                text: report.status,
                backgroundColor: badgeColor,
                textColor: badgeTextColor,
              ),
            ],
          ),
          if ((report.message ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              report.message!,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Social engagement row (likes and comments)
          Row(
            children: [
              InkWell(
                onTap: report.status == 'resolved' ? null : onLike,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 20,
                        color: report.status == 'resolved'
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${report.likeCount}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: report.status == 'resolved'
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: report.status == 'resolved' ? null : onComment,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 20,
                        color: report.status == 'resolved'
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${report.commentCount}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: report.status == 'resolved'
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Reported: ${report.timestamp.toLocal().toString().split('.')[0]}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (onResolve != null && report.status == 'open') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onResolve,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Mark resolved'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ],
          // Show a small hint when the report has been resolved and an
          // expiry is known.
          if (report.status == 'resolved' && report.expireAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                deletionHint() ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
