// Need details: what is needed, the reason, who asked.
// Donors can answer with "I have this" → share a matching item, which
// notifies the requester. The owner can mark it fulfilled / close it.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/dependencies.dart';
import '../../models/need.dart';
import '../../models/rating.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/rating_widget.dart';

class NeedDetailScreen extends StatefulWidget {
  final String needId;

  const NeedDetailScreen({super.key, required this.needId});

  @override
  State<NeedDetailScreen> createState() => _NeedDetailScreenState();
}

class _NeedDetailScreenState extends State<NeedDetailScreen> {
  late final Stream<Need?> _need = Dependencies.needs.watchNeed(widget.needId);

  Future<void> _setStatus(Need need, bool fulfilled) async {
    final ok = await confirmAction(
      context,
      title: fulfilled ? 'Mark as received?' : 'Close this need?',
      message: fulfilled
          ? 'Great news! It will no longer be shown to donors.'
          : 'It will no longer be shown to donors.',
    );
    if (!ok) return;
    try {
      if (fulfilled) {
        await Dependencies.needs.markFulfilled(need.id);
      } else {
        await Dependencies.needs.close(need.id);
      }
      if (mounted) showSnack(context, 'Updated');
    } catch (e) {
      if (mounted) showSnack(context, 'Could not update: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Need')),
      body: StreamBuilder<Need?>(
        stream: _need,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(snapshot.error);
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const LoadingView();
          }
          final need = snapshot.data;
          if (need == null) {
            return const EmptyState(icon: Icons.help_outline, title: 'Need not found');
          }
          final isMine = need.requesterId == Dependencies.auth.currentUid;
          final category = AppCategories.byId(need.categoryId);
          final canDonate = context.watch<UserProvider>().canDonate;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(need.title,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  StatusChip(need.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${category.name} · ${[need.city, need.district].where((s) => s.isNotEmpty).join(', ')} · ${Formatters.timeAgo(need.createdAt)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),
              const Text('Why they need it', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('“${need.reason}”',
                    style: const TextStyle(fontStyle: FontStyle.italic, height: 1.4)),
              ),
              if (need.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Details', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(need.description, style: const TextStyle(height: 1.4)),
              ],
              const SizedBox(height: 20),
              _RequesterCard(userId: need.requesterId, isMine: isMine),
              const SizedBox(height: 24),
              if (isMine && need.isOpen) ...[
                PrimaryButton(
                  text: 'I received it — mark fulfilled',
                  onPressed: () => _setStatus(need, true),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _setStatus(need, false),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('Close this need'),
                ),
              ],
              if (!isMine && need.isOpen)
                PrimaryButton(
                  text: 'I have this — share it',
                  onPressed: () {
                    if (!canDonate) {
                      showSnack(context,
                          'Your role is Requester. Switch to Donor or Both in Edit Profile to share.',
                          error: true);
                      return;
                    }
                    context.push('/share', extra: need);
                  },
                ),
              if (!isMine) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => context.push('/report', extra: {
                    'targetType': 'user',
                    'targetId': need.requesterId,
                    'label': 'the person who posted "${need.title}"',
                  }),
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text('Report'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RequesterCard extends StatefulWidget {
  final String userId;
  final bool isMine;

  const _RequesterCard({required this.userId, required this.isMine});

  @override
  State<_RequesterCard> createState() => _RequesterCardState();
}

class _RequesterCardState extends State<_RequesterCard> {
  late final Stream<AppUser?> _user = Dependencies.users.watchUser(widget.userId);
  late final Stream<RatingSummary> _rating = Dependencies.reviews.ratingFor(widget.userId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _user,
      builder: (context, snapshot) {
        final u = snapshot.data;
        final name = u?.displayName ?? 'Shareloop member';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondaryBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              UserAvatar(name: name, photoUrl: u?.photoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.isMine ? '$name (you)' : name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    StreamBuilder<RatingSummary>(
                      stream: _rating,
                      builder: (context, r) {
                        final s = r.data ?? RatingSummary.empty;
                        return StarRating(value: s.average, count: s.count, size: 14);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
