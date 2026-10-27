// Small reusable UI pieces used across screens.

import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../utils/api_exception.dart';
import '../utils/helpers.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = AppStatus.color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        AppStatus.label(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.tertiary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final Object? error;

  const ErrorView(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    final e = error;
    final hint = e is ApiException
        ? e.message
        : 'Cannot reach the Shareloop server. Check your connection and try again.';
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Could not load data',
      message: hint,
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: AppColors.brandPrimary),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;

  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.tertiary,
      backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: AppColors.brandPrimary,
              ),
            ),
    );
  }
}

/// Item photo with a friendly placeholder when there's no image.
class ItemImage extends StatelessWidget {
  final String? url;
  final double height;
  final double? width;
  final BorderRadius borderRadius;
  final String categoryId;

  const ItemImage({
    super.key,
    required this.url,
    this.height = 180,
    this.width = double.infinity,
    this.borderRadius = BorderRadius.zero,
    this.categoryId = 'other',
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      width: width,
      color: AppColors.surfaceSecondaryBg,
      child: Center(
        child: Icon(
          AppCategories.byId(categoryId).icon,
          color: AppColors.tertiary,
          size: height.isFinite ? height * 0.3 : 48,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: borderRadius,
      child: (url == null || url!.isEmpty)
          ? placeholder
          : Image.network(
              url!,
              height: height,
              width: width,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
    );
  }
}

/// Shows a message in a SnackBar.
void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.redAccent : AppColors.brandPrimary,
    ),
  );
}

/// Asks the user to confirm an action. Returns true on "yes".
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Yes',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}
