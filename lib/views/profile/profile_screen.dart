// Profile tab: user info, stats, eco points and menu.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/badge.dart';
import '../../models/rating.dart';
import '../../models/user.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/rating_widget.dart';
import '../../config/dependencies.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final ok = await confirmAction(context,
        title: 'Sign out?', message: 'You can sign in again with your phone number.',
        confirmText: 'Sign out');
    if (!ok || !context.mounted) return;
    await Dependencies.notifications.stop();
    await Dependencies.auth.signOut();
    if (!context.mounted) return;
    Provider.of<UserProvider>(context, listen: false).clear();
    context.go('/welcome');
  }

  Future<void> _pickLanguage(BuildContext context) async {
    const options = {'en': 'English', 'si': 'සිංහල', 'ta': 'தமிழ்'};
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in options.entries)
              ListTile(
                title: Text(e.value),
                trailing: lang.appLocale.languageCode == e.key
                    ? const Icon(Icons.check, color: AppColors.brandPrimary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(e.key),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await lang.changeLanguage(Locale(picked));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final profile = user.profile;
    final t = AppLocalizations.of(context)!;

    if (profile == null) {
      return EmptyState(
        icon: Icons.person_outline,
        title: 'Loading your profile…',
        message: 'If this takes long, finish profile setup or check your connection.',
        action: OutlinedButton(
          onPressed: () => context.push('/profile-setup'),
          child: const Text('Complete profile'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _header(context, profile),
        const SizedBox(height: 20),
        _stats(profile),
        const SizedBox(height: 20),
        _menuTile(context, Icons.edit_outlined, 'Edit profile', '/profile/edit'),
        _menuTile(context, Icons.inventory_2_outlined, 'My items', '/my-items'),
        _menuTile(context, Icons.campaign_outlined, 'My needs', '/my-needs'),
        _menuTile(context, Icons.history, 'Donation & request history', '/history'),
        _menuTile(context, Icons.emoji_events_outlined, 'Badges & leaderboard', '/badges'),
        _menuTile(context, Icons.notifications_outlined, t.notifications, '/notifications'),
        ListTile(
          leading: const Icon(Icons.language, color: AppColors.brandPrimary),
          title: Text(t.language),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pickLanguage(context),
        ),
        if (user.isAdmin)
          _menuTile(context, Icons.admin_panel_settings_outlined,
              'Admin: reports', '/admin/reports'),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.colorError),
          title: Text(t.signOut, style: const TextStyle(color: AppColors.colorError)),
          onTap: () => _signOut(context),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, AppUser p) {
    final roleLabel = p.roleType.label;
    final tier = AchievementEngine.currentTier(p.donationCount);
    return Row(
      children: [
        UserAvatar(name: p.displayName, photoUrl: p.photoUrl, radius: 36),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.displayName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('$roleLabel · ${p.district}',
                  style: const TextStyle(color: AppColors.textSecondary)),
              if (tier != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium, size: 16, color: tier.color),
                      const SizedBox(width: 4),
                      Text('${tier.title} · ${tier.level}',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, color: tier.color)),
                    ],
                  ),
                ),
              if (p.phone != null)
                Text(Formatters.phone(p.phone),
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(height: 4),
              StreamBuilder<RatingSummary>(
                stream: Dependencies.reviews.ratingFor(p.uid),
                builder: (context, s) {
                  final r = s.data ?? RatingSummary.empty;
                  return StarRating(value: r.average, count: r.count, size: 14);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stats(AppUser p) {
    final points = AchievementEngine.ecoPoints(donations: p.donationCount, requests: p.requestCount);
    Widget stat(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandPrimary)),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          stat('${p.donationCount}', 'Donations'),
          stat('${p.requestCount}', 'Requests'),
          stat('$points', 'Eco points'),
        ],
      ),
    );
  }

  Widget _menuTile(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: AppColors.brandPrimary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    );
  }
}
