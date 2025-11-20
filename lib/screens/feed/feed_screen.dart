import 'package:carlet/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:carlet/models/report_model.dart';
import 'package:carlet/services/auth_service.dart';
import 'package:carlet/services/report_service.dart';
import 'package:carlet/services/comment_service.dart';
import 'package:carlet/widgets/report_card.dart';
import 'package:carlet/widgets/carlet_button.dart';
import 'package:carlet/utils/snackbar.dart';
import 'package:carlet/screens/comments/comments_screen.dart';
import 'package:carlet/screens/report/create_report_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _commentService = CommentService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportService = ReportService();
    return Scaffold(
      body: StreamBuilder<List<Report>>(
        stream: reportService.streamReports(limit: 200),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Show error state with retry button
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load alerts',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CarletButton.outlined(
                      text: 'Retry',
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        setState(() {}); // Trigger rebuild to retry stream
                      },
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = snapshot.data!;
          if (reports.isEmpty) {
            // Empty state with improved visual hierarchy
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No alerts yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Be the first to report!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    // CTA styled to be rounded and shrink-to-fit text width
                    Theme(
                      data: Theme.of(context).copyWith(
                        elevatedButtonTheme: ElevatedButtonThemeData(
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all<OutlinedBorder>(
                              const StadiumBorder(),
                            ),
                            minimumSize: WidgetStateProperty.all(const Size(0, 44)),
                            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                            backgroundColor: WidgetStateProperty.all(theme.colorScheme.primary),
                            foregroundColor: WidgetStateProperty.all(theme.colorScheme.onPrimary),
                          ),
                        ),
                      ),
                      child: IntrinsicWidth(
                        child: Center(
                          child: CarletButton.primary(
                            text: 'Post',
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              final result = await navigator.pushNamed(
                                CreateReportScreen.routeName,
                              );
                              if (!context.mounted) return;
                              if (result == true) {
                                AppSnackbar.showSuccess(context, 'Report posted.');
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                onLike: () async {
                  final userId = user?.id;
                  if (userId == null) return;
                  await _commentService.toggleLike(r.id, userId);
                },
                onComment: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CommentsScreen(report: r),
                    ),
                  );
                },
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final navigator = Navigator.of(context);
          final result = await navigator.pushNamed(
            CreateReportScreen.routeName,
          );
          if (!context.mounted) return;
          if (result == true) {
            AppSnackbar.showSuccess(context, 'Report posted.');
          }
        },
        icon: const Icon(Icons.add, color: AppColors.lightSurface,),
        label: const Text('Report', style: TextStyle(color: AppColors.lightSurface),),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
