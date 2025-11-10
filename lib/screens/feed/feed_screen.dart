import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:carlet/models/report_model.dart';
import 'package:carlet/services/auth_service.dart';
import 'package:carlet/services/report_service.dart';
import 'package:carlet/widgets/report_card.dart';
import 'package:carlet/utils/snackbar.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();
    return StreamBuilder<List<Report>>(
      stream: reportService.streamReports(limit: 200),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Show a helpful error instead of an indefinite loading spinner
          return Center(
            child: Text('Failed to load reports: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data!;
        if (reports.isEmpty) {
          return const Center(
            child: Text('No alerts yet. Be the first to report!'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final r = reports[index];
            final user = context.read<AuthService>().currentUser;
            final canResolve = (user?.carPlate != null &&
                r.licensePlate != null &&
                user!.carPlate!.toUpperCase().replaceAll(' ', '') ==
                    r.licensePlate!.toUpperCase().replaceAll(' ', ''));
            return ReportCard(
              report: r,
              onResolve: canResolve
                  ? () async {
                      await reportService.markResolved(r.id);
                      if (!context.mounted) return;
                      // show success flushbar
                      AppSnackbar.showSuccess(context, 'Marked as resolved.');
                    }
                  : null,
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
        );
      },
    );
  }
}
