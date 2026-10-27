import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/constants.dart';
import '../models/need.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';
import 'app_widgets.dart';

/// Card for a need post (reused in Explore and My needs — DRY).
class NeedCard extends StatelessWidget {
  final Need need;

  const NeedCard({super.key, required this.need});

  @override
  Widget build(BuildContext context) {
    final category = AppCategories.byId(need.categoryId);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/need/${need.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.surfaceSecondaryBg,
                child: Icon(category.icon, color: AppColors.brandPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            need.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        StatusChip(need.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '“${need.reason}”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category.name} · ${need.district} · ${Formatters.timeAgo(need.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
