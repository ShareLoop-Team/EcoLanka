// Admin only (users/{uid}.role == 'admin', set manually in the console):
// review reports, remove reported items, ban reported users.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../utils/formatters.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_widgets.dart';
import '../../config/dependencies.dart';
import '../../models/report.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  late final Stream<List<Report>> _reports = Dependencies.reports.allReports();

  Future<void> _act(Report r, String action) async {
    try {
      switch (action) {
        case 'remove_item':
          await Dependencies.items.setStatus(r.targetId, 'removed');
          await Dependencies.reports.setStatus(r.id, 'resolved');
          break;
        case 'ban_user':
          await Dependencies.users.setBanned(r.targetId, true);
          await Dependencies.reports.setStatus(r.id, 'resolved');
          break;
        case 'dismiss':
          await Dependencies.reports.setStatus(r.id, 'dismissed');
          break;
        case 'resolve':
          await Dependencies.reports.setStatus(r.id, 'resolved');
          break;
      }
      if (mounted) showSnack(context, 'Done');
    } catch (e) {
      if (mounted) showSnack(context, 'Failed: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports (admin)')),
      body: StreamBuilder<List<Report>>(
        stream: _reports,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(snapshot.error);
          if (!snapshot.hasData) return const LoadingView();
          final list = snapshot.data!;
          if (list.isEmpty) {
            return const EmptyState(
                icon: Icons.verified_user_outlined, title: 'No reports');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final r = list[i];
              final open = r.status == 'open' || r.status == 'reviewing';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            r.targetType == 'item'
                                ? Icons.inventory_2_outlined
                                : Icons.person_outline,
                            color: AppColors.brandPrimary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ReportReasons.labels[r.reason] ?? r.reason,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(r.status,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: open ? AppColors.colorError : Colors.grey)),
                        ],
                      ),
                      if (r.details.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(r.details),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        '${r.targetType} ${r.targetId} · ${Formatters.timeAgo(r.createdAt)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary),
                      ),
                      if (open)
                        Wrap(
                          spacing: 4,
                          children: [
                            if (r.targetType == 'item')
                              TextButton(
                                onPressed: () => context.push('/item/${r.targetId}'),
                                child: const Text('View item'),
                              ),
                            if (r.targetType == 'item')
                              TextButton(
                                onPressed: () => _act(r, 'remove_item'),
                                child: const Text('Remove item'),
                              ),
                            if (r.targetType == 'user')
                              TextButton(
                                onPressed: () => _act(r, 'ban_user'),
                                child: const Text('Ban user'),
                              ),
                            TextButton(
                              onPressed: () => _act(r, 'resolve'),
                              child: const Text('Mark resolved'),
                            ),
                            TextButton(
                              onPressed: () => _act(r, 'dismiss'),
                              child: const Text('Dismiss'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
