// Donation & request history.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../models/item.dart';
import '../../models/request.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/request_card.dart';
import '../../config/dependencies.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final Stream<List<Item>> _items = Dependencies.items.myItems();
  late final Stream<List<ShareRequest>> _sent = Dependencies.requests.sentRequests();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          bottom: const TabBar(
            labelColor: AppColors.brandPrimary,
            indicatorColor: AppColors.brandPrimary,
            tabs: [Tab(text: 'Donations'), Tab(text: 'Requests')],
          ),
        ),
        body: TabBarView(
          children: [
            StreamBuilder<List<Item>>(
              stream: _items,
              builder: (context, snapshot) {
                if (snapshot.hasError) return ErrorView(snapshot.error);
                if (!snapshot.hasData) return const LoadingView();
                final donated =
                    snapshot.data!.where((i) => i.status == 'donated').toList();
                if (donated.isEmpty) {
                  return const EmptyState(
                    icon: Icons.volunteer_activism_outlined,
                    title: 'No completed donations yet',
                    message: 'Items you hand over appear here.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: donated.length,
                  itemBuilder: (context, i) {
                    final item = donated[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.check_circle,
                            color: AppColors.brandPrimary),
                        title: Text(item.title),
                        subtitle: Text('Posted ${Formatters.date(item.createdAt)}'),
                        onTap: () => context.push('/item/${item.id}'),
                      ),
                    );
                  },
                );
              },
            ),
            StreamBuilder<List<ShareRequest>>(
              stream: _sent,
              builder: (context, snapshot) {
                if (snapshot.hasError) return ErrorView(snapshot.error);
                if (!snapshot.hasData) return const LoadingView();
                final list = snapshot.data!;
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.outbox_outlined,
                    title: 'No requests yet',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, i) => RequestCard(
                    request: list[i],
                    incoming: false,
                    onTap: () => context.push('/request/${list[i].id}'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
