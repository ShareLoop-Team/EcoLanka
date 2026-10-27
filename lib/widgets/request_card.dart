import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/request.dart';
import '../utils/formatters.dart';
import 'app_widgets.dart';

class RequestCard extends StatelessWidget {
  final ShareRequest request;
  final bool incoming; // true = someone requested my item
  final VoidCallback onTap;

  const RequestCard({
    super.key,
    required this.request,
    required this.incoming,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondaryBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  incoming ? Icons.move_to_inbox_rounded : Icons.outbox_rounded,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.itemTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.timeAgo(request.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(request.status),
            ],
          ),
        ),
      ),
    );
  }
}
