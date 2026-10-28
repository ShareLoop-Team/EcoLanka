// Items I've shared, with their status.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../models/item.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_widgets.dart';
import '../../config/dependencies.dart';

class MyItemsScreen extends StatelessWidget {
  const MyItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My items')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/share'),
        icon: const Icon(Icons.add),
        label: const Text('Share item'),
      ),
      body: StreamBuilder<List<Item>>(
        stream: Dependencies.items.myItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(snapshot.error);
          if (!snapshot.hasData) return const LoadingView();
          final items = snapshot.data!.where((i) => i.status != 'removed').toList();
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'You haven\'t shared anything yet',
              message: 'Tap "Share item" to give something away.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final item = items[i];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ItemImage(
                    url: item.images.isEmpty ? null : item.images.first,
                    categoryId: item.categoryId,
                    height: 56,
                    width: 56,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(item.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      '${item.requestCount} requests · ${Formatters.timeAgo(item.createdAt)}'),
                  trailing: StatusChip(item.status),
                  onTap: () => context.push('/item/${item.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
