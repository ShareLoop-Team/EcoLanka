// Item details: photos, info, donor + rating, and actions
// (request / view my request / manage my item / report).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/request_card.dart';
import '../../models/item.dart';
import '../../models/rating.dart';
import '../../models/request.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/rating_widget.dart';
import '../../config/dependencies.dart';

class ItemDetailScreen extends StatelessWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Item?>(
      stream: Dependencies.items.watchItem(itemId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(appBar: AppBar(), body: ErrorView(snapshot.error));
        }
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Scaffold(appBar: AppBar(), body: const LoadingView());
        }
        final item = snapshot.data;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Item not found',
              message: 'It may have been removed by the donor.',
            ),
          );
        }
        return _ItemDetailView(item: item);
      },
    );
  }
}

class _ItemDetailView extends StatefulWidget {
  final Item item;

  const _ItemDetailView({required this.item});

  @override
  State<_ItemDetailView> createState() => _ItemDetailViewState();
}

class _ItemDetailViewState extends State<_ItemDetailView> {
  late final Future<ShareRequest?> _myRequest;
  int _page = 0;

  bool get _isMine => widget.item.donorId == Dependencies.auth.currentUid;

  @override
  void initState() {
    super.initState();
    _myRequest = _isMine
        ? Future.value(null)
        : Dependencies.requests.myRequestFor(widget.item.id).catchError((_) => null);
  }

  Future<void> _changeStatus(String status) async {
    final ok = await confirmAction(
      context,
      title: status == 'removed' ? 'Remove item?' : 'Change status?',
      message: status == 'removed'
          ? 'It will no longer be shown to others.'
          : 'Set this item to "${AppStatus.label(status)}"?',
    );
    if (!ok) return;
    try {
      await Dependencies.items.setStatus(widget.item.id, status);
      if (mounted) showSnack(context, 'Item updated');
    } catch (e) {
      if (mounted) showSnack(context, 'Could not update: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final category = AppCategories.byId(item.categoryId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(category.name),
        actions: [
          if (!_isMine)
            IconButton(
              tooltip: 'Report item',
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => context.push('/report', extra: {
                'targetType': 'item',
                'targetId': item.id,
                'label': item.title,
              }),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _gallery(item),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(item.status),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoChip(Icons.check_circle_outline, AppConditions.label(item.condition)),
                    _infoChip(Icons.location_on_outlined,
                        [item.city, item.district].where((s) => s.isNotEmpty).join(', ')),
                    _infoChip(Icons.schedule, Formatters.timeAgo(item.createdAt)),
                    _infoChip(Icons.people_outline, '${item.requestCount} requests'),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Description',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(item.description,
                    style: const TextStyle(
                        fontSize: 14, height: 1.5, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                _DonorCard(donorId: item.donorId, isMine: _isMine),
                const SizedBox(height: 24),
                _actions(item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gallery(Item item) {
    if (item.images.isEmpty) {
      return ItemImage(url: null, categoryId: item.categoryId, height: 260);
    }
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: item.images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => ItemImage(
              url: item.images[i],
              categoryId: item.categoryId,
              height: 280,
            ),
          ),
          if (item.images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < item.images.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page ? Colors.white : Colors.white54,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brandPrimary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _actions(Item item) {
    if (_isMine) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RequestsForItem(item: item),
          const SizedBox(height: 16),
          if (item.status == 'reserved')
            OutlinedButton.icon(
              onPressed: () => _changeStatus('available'),
              icon: const Icon(Icons.undo),
              label: const Text('Make available again'),
            ),
          if (item.status == 'available' || item.status == 'reserved')
            TextButton.icon(
              onPressed: () => _changeStatus('removed'),
              icon: const Icon(Icons.delete_outline, color: AppColors.colorError),
              label: const Text('Remove listing',
                  style: TextStyle(color: AppColors.colorError)),
            ),
        ],
      );
    }

    return FutureBuilder<ShareRequest?>(
      future: _myRequest,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        final existing = snapshot.data;
        if (existing != null) {
          return PrimaryButton(
            text: 'View my request (${AppStatus.label(existing.status)})',
            onPressed: () => context.push('/request/${existing.id}'),
          );
        }
        if (item.status != 'available') {
          return PrimaryButton(text: 'Not available — ${AppStatus.label(item.status)}');
        }
        final canRequest = context.watch<UserProvider>().canRequest;
        return PrimaryButton(
          text: AppLocalizations.of(context)!.requestItem,
          onPressed: () {
            if (!canRequest) {
              showSnack(context,
                  'Your role is Donor. Switch to Requester or Both in Edit Profile to request items.',
                  error: true);
              return;
            }
            context.push('/item/${item.id}/request', extra: item);
          },
        );
      },
    );
  }
}

class _DonorCard extends StatefulWidget {
  final String donorId;
  final bool isMine;

  const _DonorCard({required this.donorId, required this.isMine});

  @override
  State<_DonorCard> createState() => _DonorCardState();
}

class _DonorCardState extends State<_DonorCard> {
  late final Stream<AppUser?> _user = Dependencies.users.watchUser(widget.donorId);
  late final Stream<RatingSummary> _rating =
      Dependencies.reviews.ratingFor(widget.donorId);

  String get donorId => widget.donorId;
  bool get isMine => widget.isMine;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _user,
      builder: (context, snapshot) {
        final donor = snapshot.data;
        final name = donor?.displayName ?? 'Shareloop member';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondaryBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              UserAvatar(name: name, photoUrl: donor?.photoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isMine ? '$name (you)' : name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    StreamBuilder<RatingSummary>(
                      stream: _rating,
                      builder: (context, r) {
                        final s = r.data ?? RatingSummary.empty;
                        return StarRating(value: s.average, count: s.count, size: 14);
                      },
                    ),
                    if (donor != null) ...[
                      const SizedBox(height: 4),
                      Text('${donor.donationCount} donations · ${donor.district}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              if (!isMine)
                IconButton(
                  tooltip: 'Report user',
                  icon: const Icon(Icons.flag_outlined, size: 20),
                  onPressed: () => context.push('/report', extra: {
                    'targetType': 'user',
                    'targetId': donorId,
                    'label': name,
                  }),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Donor selection (docs §4.2): every request for my item with the
/// requester's reason. Choosing one declines the others automatically.
class _RequestsForItem extends StatefulWidget {
  final Item item;

  const _RequestsForItem({required this.item});

  @override
  State<_RequestsForItem> createState() => _RequestsForItemState();
}

class _RequestsForItemState extends State<_RequestsForItem> {
  late final Stream<List<ShareRequest>> _requests =
      Dependencies.requests.requestsForItem(widget.item.id);
  bool _busy = false;

  Future<void> _select(ShareRequest r) async {
    final ok = await confirmAction(
      context,
      title: 'Give the item to this person?',
      message: 'Their contact details will be unlocked and all other requests '
          'will be declined automatically.',
      confirmText: 'Select',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await Dependencies.requests.accept(r);
      if (mounted) showSnack(context, 'Requester selected 🎉');
    } catch (e) {
      if (mounted) showSnack(context, 'Could not select: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShareRequest>>(
      stream: _requests,
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorView(snapshot.error);
        if (!snapshot.hasData) return const LoadingView();
        final list = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              list.isEmpty
                  ? 'No requests yet'
                  : 'Requests (${list.length}) — read each reason and choose',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_busy) const LoadingView(),
            for (final r in list)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RequestCard(
                    request: r,
                    incoming: true,
                    onTap: () => context.push('/request/${r.id}'),
                  ),
                  if (r.isPending && widget.item.status == 'available' && !_busy)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _select(r),
                              child: const Text('Select'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.push('/request/${r.id}'),
                              style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50)),
                              child: const Text('View'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
