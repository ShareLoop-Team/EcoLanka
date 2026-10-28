// Main app shell: bottom navigation (Home · Explore · Share · Requests · Profile),
// the home feed, the notification bell and in-app notification banners.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../controllers/item_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/item.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../utils/district_locator.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/item_card.dart';
import '../profile/profile_screen.dart';
import '../requests/my_requests_screen.dart';
import 'explore_screen.dart';
import '../../config/dependencies.dart';

const Color _green = Color(0xFF075B3A);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Explore tab is rebuilt with a new key when opened from a category/search.
  String? _exploreCategory;
  String _exploreQuery = '';
  Key _exploreKey = UniqueKey();

  StreamSubscription<AppUser?>? _profileSub;
  late final Stream<int> _unread = Dependencies.notifications.unreadCount();

  @override
  void initState() {
    super.initState();

    // Keep the signed-in user's profile in the provider.
    _profileSub = Dependencies.users.watchCurrentUser().listen((profile) {
      if (!mounted) return;
      Provider.of<UserProvider>(context, listen: false).setProfile(profile);
    }, onError: (_) {});

    // In-app banner for new notifications.
    Dependencies.notifications.start((n) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${n.title}\n${n.body}'),
          backgroundColor: AppColors.brandPrimary,
          action: n.requestId == null && n.itemId == null
              ? null
              : SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () => context.push(n.requestId != null
                      ? '/request/${n.requestId}'
                      : '/item/${n.itemId}'),
                ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  void _openExplore({String? category, String query = ''}) {
    setState(() {
      _exploreCategory = category;
      _exploreQuery = query;
      _exploreKey = UniqueKey();
      _currentIndex = 1;
    });
  }

  /// "+" button: give away an item or post something you need.
  Future<void> _openShare() async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final t = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.volunteer_activism, color: AppColors.brandPrimary),
              title: Text(t.shareItem),
              subtitle: const Text('Give away something you no longer use'),
              enabled: user.canDonate,
              onTap: () => Navigator.of(ctx).pop('share'),
            ),
            ListTile(
              leading: const Icon(Icons.campaign_outlined, color: AppColors.brandPrimary),
              title: Text(t.postNeed),
              subtitle: const Text('Describe what you need and why'),
              enabled: user.canRequest,
              onTap: () => Navigator.of(ctx).pop('need'),
            ),
            if (!user.canDonate || !user.canRequest)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'Some options depend on your role. Change it in Profile → Edit profile.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    context.push(choice == 'share' ? '/share' : '/need/new');
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeFeed(onOpenExplore: _openExplore, onShare: _openShare),
      ExploreScreen(
        key: _exploreKey,
        initialCategory: _exploreCategory,
        initialQuery: _exploreQuery,
      ),
      const SizedBox.shrink(), // centre "+" button opens the share screen
      const MyRequestsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFA),
      appBar: _currentIndex == 0 ? _buildTopBar() : null,
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: pages),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildTopBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _green.withValues(alpha: 0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                AppImages.logo,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.brandPrimary,
                    child: const Icon(Icons.eco, color: Colors.white, size: 22),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EcoLanka',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F2D21),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: _green),
                    const SizedBox(width: 2),
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        return Flexible(
                          child: Text(
                            '${userProvider.district}, Sri Lanka',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        StreamBuilder<int>(
          stream: _unread,
          builder: (context, snapshot) {
            final unread = snapshot.data ?? 0;
            return IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.push('/notifications'),
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                backgroundColor: AppColors.brandPrimary,
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.black87),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    final t = AppLocalizations.of(context)!;
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, t.navHome),
          _buildNavItem(1, Icons.search_rounded, t.navExplore),
          GestureDetector(
            onTap: _openShare,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                    LinearGradient(colors: [_green, Color(0xFF2ECC71)]),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 26),
            ),
          ),
          _buildNavItem(3, Icons.list_alt_rounded, t.navRequests),
          _buildNavItem(4, Icons.person_outline_rounded, t.navProfile),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? _green : Colors.grey, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? _green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home tab: search, categories and live "recommended" items
/// (items in the user's district first, then everything else).
class _HomeFeed extends StatefulWidget {
  final void Function({String? category, String query}) onOpenExplore;
  final VoidCallback onShare;

  const _HomeFeed({required this.onOpenExplore, required this.onShare});

  @override
  State<_HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<_HomeFeed> {
  late final Stream<List<Item>> _items = Dependencies.items.availableItems();

  void Function({String? category, String query}) get onOpenExplore =>
      widget.onOpenExplore;
  VoidCallback get onShare => widget.onShare;

  @override
  Widget build(BuildContext context) {
    final district = context.watch<UserProvider>().district;
    final myUid = Dependencies.auth.currentUid;
    final t = AppLocalizations.of(context)!;

    return StreamBuilder<List<Item>>(
      stream: _items,
      builder: (context, snapshot) {
        final children = <Widget>[
          _buildSearchBar(t),
          const SizedBox(height: 24),
          _buildCategoriesSection(t),
          const SizedBox(height: 28),
          _buildRecommendedHeader(t),
          const SizedBox(height: 14),
        ];

        if (snapshot.hasError) {
          children.add(ErrorView(snapshot.error));
        } else if (!snapshot.hasData) {
          children.add(const LoadingView());
        } else {
          final mine = snapshot.data!.where((i) => i.donorId != myUid).toList();
          final items = ItemController.sortByProximity(mine, district);
          if (items.isEmpty) {
            children.add(EmptyState(
              icon: Icons.volunteer_activism_outlined,
              title: 'No items yet',
              message: 'Be the first to share something with your community.',
              action: ElevatedButton(
                onPressed: onShare,
                child: Text(t.shareItem),
              ),
            ));
          } else {
            for (final item in items.take(20)) {
              children
                ..add(ItemCard(
                  imageUrl: item.images.isEmpty ? '' : item.images.first,
                  categoryId: item.categoryId,
                  title: item.title,
                  location: [
                    [item.city, item.district].where((s) => s.isNotEmpty).join(', '),
                    DistrictLocator.distanceLabel(district, item.district),
                  ].join(' · '),
                  badgeText: AppConditions.label(item.condition),
                  priceTag: t.free,
                  buttonText: t.requestItem,
                  onTap: () => context.push('/item/${item.id}'),
                  onRequest: () => context.push('/item/${item.id}'),
                ))
                ..add(const SizedBox(height: 16));
            }
          }
        }
        children.add(const SizedBox(height: 30));

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: children,
        );
      },
    );
  }

  Widget _buildSearchBar(AppLocalizations t) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        textInputAction: TextInputAction.search,
        onSubmitted: (q) => onOpenExplore(query: q.trim()),
        decoration: InputDecoration(
          hintText: t.searchHint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune, size: 18, color: _green),
            onPressed: () => onOpenExplore(),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t.categories,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            GestureDetector(
              onTap: () => onOpenExplore(),
              child: Text('${t.viewAll} >',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: _green)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: AppCategories.all.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final cat = AppCategories.all[index];
              return GestureDetector(
                onTap: () => onOpenExplore(category: cat.id),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Icon(cat.icon, color: _green, size: 24),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 76,
                      child: Text(cat.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedHeader(AppLocalizations t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.recommendedForYou,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              Text(t.recommendedSubtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(t.nearYou,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: _green)),
        ),
      ],
    );
  }
}
