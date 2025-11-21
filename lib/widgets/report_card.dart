import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:carlet/models/report_model.dart';
import 'package:carlet/widgets/carlet_badge.dart';

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
    
    // Calculate minutes elapsed since report
    String getTimeAgo() {
      final now = DateTime.now().toUtc();
      final reportTime = report.timestamp.toUtc();
      final diff = now.difference(reportTime);
      final minutes = diff.inMinutes;
      
      if (minutes < 1) {
        return '<1 min ago';
      } else if (minutes == 1) {
        return '1 min ago';
      } else if (minutes < 60) {
        return '$minutes mins ago';
      } else if (minutes < 1440) {
        final hours = (minutes / 60).floor();
        return hours == 1 ? '1 hour ago' : '$hours hours ago';
      } else {
        final days = (minutes / 1440).floor();
        return days == 1 ? '1 day ago' : '$days days ago';
      }
    }
    
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

    return GestureDetector(
      onTapDown: (_) {},
      child: Container(
        color: theme.colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report.photoUrl != null) ...[
              SizedBox(
                width: double.infinity,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    report.photoUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Row(
            children: [
              if (report.licensePlate != null &&
                  report.licensePlate!.isNotEmpty)
                Expanded(
                  child: Text(
                    report.licensePlate!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
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
              style: theme.textTheme.titleMedium?.copyWith(
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Social engagement row with timestamp
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
                      FaIcon(
                        FontAwesomeIcons.heart,
                        size: 18,
                        color: report.status == 'resolved'
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.8),
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
                      FaIcon(
                        FontAwesomeIcons.comment,
                        size: 18,
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
              const Spacer(),
              Text(
                getTimeAgo(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          if (onResolve != null && report.status == 'open') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onResolve,
                icon: const FaIcon(FontAwesomeIcons.circleCheck, size: 16),
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
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}
