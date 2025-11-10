import 'package:flutter/material.dart';

import 'package:carlet/models/report_model.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback? onResolve;

  const ReportCard({
    super.key,
    required this.report,
    this.onResolve,
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.photoUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(report.photoUrl!, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (report.licensePlate != null &&
                        report.licensePlate!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          report.licensePlate!,
                          style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: report.status == 'open'
                            ? theme.colorScheme.errorContainer
                            : theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        report.status.toUpperCase(),
                        style: TextStyle(
                          color: report.status == 'open'
                              ? theme.colorScheme.onErrorContainer
                              : theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                if ((report.message ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    report.message!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Reported: ${report.timestamp.toLocal().toString().split('.')[0]}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                if (onResolve != null && report.status == 'open')
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: onResolve,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark resolved'),
                    ),
                  ),
                // Show a small hint when the report has been resolved and an
                // expiry is known.
                if (report.status == 'resolved' && report.expireAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      deletionHint() ?? '',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
