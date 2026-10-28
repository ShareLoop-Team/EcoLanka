import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_widgets.dart';
import '../../config/dependencies.dart';
import '../../models/app_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final Stream<List<AppNotification>> _stream =
      Dependencies.notifications.myNotifications();
  List<AppNotification> _latest = const [];

  IconData _icon(String type) {
    switch (type) {
      case 'new_request':
        return Icons.move_to_inbox_rounded;
      case 'request_accepted':
        return Icons.check_circle_outline;
      case 'request_rejected':
      case 'request_cancelled':
        return Icons.cancel_outlined;
      case 'request_completed':
        return Icons.celebration_outlined;
      case 'need_match':
        return Icons.card_giftcard;
    }
    return Icons.notifications_none;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => Dependencies.notifications.markAllRead(_latest),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(snapshot.error);
          if (!snapshot.hasData) return const LoadingView();
          final list = snapshot.data!;
          _latest = list;
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              title: 'No notifications yet',
              message: 'Request updates will show up here.',
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = list[i];
              return ListTile(
                tileColor: n.read ? null : const Color(0xFFF1F8F2),
                leading: CircleAvatar(
                  backgroundColor: AppColors.surfaceSecondaryBg,
                  child: Icon(_icon(n.type), color: AppColors.brandPrimary),
                ),
                title: Text(n.title,
                    style: TextStyle(
                        fontWeight: n.read ? FontWeight.w500 : FontWeight.bold)),
                subtitle: Text('${n.body}\n${Formatters.timeAgo(n.createdAt)}'),
                isThreeLine: true,
                onTap: () {
                  if (!n.read) Dependencies.notifications.markRead(n.id);
                  if (n.requestId != null) {
                    context.push('/request/${n.requestId}');
                  } else if (n.itemId != null) {
                    context.push('/item/${n.itemId}');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
