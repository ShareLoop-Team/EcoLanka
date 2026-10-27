// Badges (Bronze → Platinum) + top-donor leaderboards (this month / all time).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/dependencies.dart';
import '../../controllers/user_controller.dart';
import '../../models/badge.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/user_badge.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  late final Stream<List<AppUser>> _monthly = Dependencies.users.monthlyLeaderboard();
  late final Stream<List<AppUser>> _allTime = Dependencies.users.leaderboard();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProvider>().profile;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Badges & leaderboard'),
          bottom: const TabBar(
            labelColor: AppColors.brandPrimary,
            indicatorColor: AppColors.brandPrimary,
            tabs: [
              Tab(text: 'My badges'),
              Tab(text: 'This month'),
              Tab(text: 'All time'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            profile == null ? const LoadingView() : _myBadges(profile),
            _leaderboard(_monthly, profile, monthly: true),
            _leaderboard(_allTime, profile, monthly: false),
          ],
        ),
      ),
    );
  }

  Widget _myBadges(AppUser profile) {
    final donations = profile.donationCount;
    final current = AchievementEngine.currentTier(donations);
    final next = AchievementEngine.nextTier(donations);
    final badges = AchievementEngine.badges(donations);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondaryBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                current == null
                    ? 'No badge yet'
                    : '${current.title} · ${current.level}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: current?.color ?? AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$donations donations · '
                '${AchievementEngine.ecoPoints(donations: donations, requests: profile.requestCount)} eco points',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: AchievementEngine.progressToNext(donations),
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                color: next?.color ?? AppColors.brandPrimary,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 6),
              Text(
                next == null
                    ? 'You reached Platinum — Community Champion! 🏆'
                    : '${next.threshold - donations} more donations to ${next.title}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [for (final b in badges) BadgeTile(badge: b)],
          ),
        ),
      ],
    );
  }

  Widget _leaderboard(Stream<List<AppUser>> stream, AppUser? me, {required bool monthly}) {
    final monthKey = UserController.currentMonthKey;
    return StreamBuilder<List<AppUser>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorView(snapshot.error);
        if (!snapshot.hasData) return const LoadingView();
        final users = snapshot.data!;
        if (users.isEmpty) {
          return EmptyState(
            icon: Icons.emoji_events_outlined,
            title: monthly ? 'No donations this month yet' : 'No donations yet',
            message: 'Complete a donation to top the leaderboard!',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, i) {
            final u = users[i];
            final isMe = u.uid == me?.uid;
            final count = monthly ? u.donationsInMonth(monthKey) : u.donationCount;
            final tier = AchievementEngine.currentTier(u.donationCount);
            const medals = ['🥇', '🥈', '🥉'];
            return Card(
              color: isMe ? const Color(0xFFE8F5E9) : null,
              child: ListTile(
                leading: SizedBox(
                  width: 36,
                  child: Center(
                    child: Text(
                      i < 3 ? medals[i] : '#${i + 1}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                title: Text(isMe ? '${u.displayName} (you)' : u.displayName),
                subtitle: Text([u.district, if (tier != null) tier.title].join(' · ')),
                trailing: Text(
                  '$count 🎁',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
