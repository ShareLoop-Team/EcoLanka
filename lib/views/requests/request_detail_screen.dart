// Request details + actions:
//   donor:     accept / reject (pending), mark completed (accepted)
//   requester: cancel (pending / accepted)
//   both:      contact details once accepted, review after completion, report.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../models/handover_method.dart';
import '../../models/request.dart';
import '../../models/user.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/custom_button.dart';
import '../../config/dependencies.dart';

class RequestDetailScreen extends StatelessWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Request')),
      body: StreamBuilder<ShareRequest?>(
        stream: Dependencies.requests.watchRequest(requestId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(snapshot.error);
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const LoadingView();
          }
          final r = snapshot.data;
          if (r == null) {
            return const EmptyState(
              icon: Icons.help_outline,
              title: 'Request not found',
            );
          }
          return _RequestBody(request: r);
        },
      ),
    );
  }
}

class _RequestBody extends StatefulWidget {
  final ShareRequest request;

  const _RequestBody({required this.request});

  @override
  State<_RequestBody> createState() => _RequestBodyState();
}

class _RequestBodyState extends State<_RequestBody> {
  bool _busy = false;

  ShareRequest get r => widget.request;
  bool get _iAmDonor => r.donorId == Dependencies.auth.currentUid;
  String get _otherId => _iAmDonor ? r.requesterId : r.donorId;

  Future<void> _run(String confirmTitle, String confirmMsg,
      Future<void> Function() action, String done) async {
    final ok = await confirmAction(context, title: confirmTitle, message: confirmMsg);
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showSnack(context, done);
    } catch (e) {
      if (mounted) showSnack(context, 'Action failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/item/${r.itemId}'),
                child: Text(
                  r.itemTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.tertiary,
                  ),
                ),
              ),
            ),
            StatusChip(r.status),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${_iAmDonor ? 'Received' : 'Sent'} ${Formatters.timeAgo(r.createdAt)}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 20),
        _section('Reason', r.message),
        if (r.antiResellAgreed)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, size: 16, color: AppColors.brandPrimary),
                SizedBox(width: 6),
                Expanded(
                  child: Text('Requester agreed not to resell this item.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        _PersonCard(
          userId: _otherId,
          label: _iAmDonor ? 'Requested by' : 'Donor',
          showContact: r.status == 'accepted' || r.status == 'completed',
        ),
        if (r.isAccepted || r.isCompleted) ...[
          const SizedBox(height: 20),
          _handoverSection(),
        ],
        const SizedBox(height: 24),
        _timeline(),
        const SizedBox(height: 24),
        ..._actions(),
      ],
    );
  }

  Widget _section(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondaryBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(body, style: const TextStyle(height: 1.4)),
        ),
      ],
    );
  }

  /// Pickup & delivery options (docs §2.4) — any HandoverMethod works here (OCP).
  Widget _handoverSection() {
    final chosen = r.handover;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pickup / delivery', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (r.isAccepted)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in HandoverMethods.all)
                ChoiceChip(
                  avatar: Icon(m.icon, size: 16),
                  label: Text(m.title),
                  selected: chosen?.id == m.id,
                  selectedColor: AppColors.tertiary,
                  onSelected: _busy
                      ? null
                      : (_) async {
                          setState(() => _busy = true);
                          try {
                            await Dependencies.requests.setHandoverMethod(r, m);
                          } catch (e) {
                            if (mounted) showSnack(context, 'Could not save: $e', error: true);
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                ),
            ],
          ),
        if (chosen != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondaryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(chosen.icon, color: AppColors.brandPrimary, size: 18),
                    const SizedBox(width: 6),
                    Text(chosen.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(chosen.description, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                for (final tip in chosen.safetyTips())
                  Text('• $tip',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ] else if (r.isAccepted)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Agree on a method, then pick it here so you both see the same plan.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
      ],
    );
  }

  Widget _timeline() {
    const steps = ['pending', 'accepted', 'completed'];
    final failed = r.status == 'rejected' || r.status == 'cancelled';
    final current = steps.indexOf(r.status);
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Column(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: !failed && current >= i
                    ? AppColors.brandPrimary
                    : Colors.grey.shade300,
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                ['Requested', 'Accepted', 'Handed over'][i],
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 16),
                color: !failed && current > i
                    ? AppColors.brandPrimary
                    : Colors.grey.shade300,
              ),
            ),
        ],
      ],
    );
  }

  List<Widget> _actions() {
    final widgets = <Widget>[];
    if (_busy) return [const LoadingView()];

    if (_iAmDonor && r.status == 'pending') {
      widgets
        ..add(PrimaryButton(
          text: 'Select this requester',
          onPressed: () => _run('Select this requester?',
              'The item will be reserved for them, contact details are shared, '
                  'and other requests are declined automatically.',
              () => Dependencies.requests.accept(r), 'Request accepted'),
        ))
        ..add(const SizedBox(height: 10))
        ..add(OutlinedButton(
          onPressed: () => _run('Decline request?', 'They will be notified.',
              () => Dependencies.requests.reject(r), 'Request declined'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Decline'),
        ));
    }
    if (_iAmDonor && r.status == 'accepted') {
      widgets.add(PrimaryButton(
        text: 'Mark as handed over',
        onPressed: () => _run('Item handed over?',
            'This completes the donation and marks the item as donated.',
            () => Dependencies.requests.complete(r), 'Donation completed 🎉'),
      ));
    }
    if (!_iAmDonor && (r.status == 'pending' || r.status == 'accepted')) {
      widgets.add(OutlinedButton(
        onPressed: () => _run('Cancel request?', 'The donor will be notified.',
            () => Dependencies.requests.cancel(r), 'Request cancelled'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        child: const Text('Cancel request'),
      ));
    }
    if (r.status == 'completed') {
      widgets.add(FutureBuilder<bool>(
        future: Dependencies.reviews.hasReviewed(r.id),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return const Center(
              child: Text('✓ You reviewed this exchange',
                  style: TextStyle(color: AppColors.brandPrimary)),
            );
          }
          return PrimaryButton(
            text: 'Leave a review',
            onPressed: snapshot.hasData
                ? () async {
                    await context.push('/review', extra: r);
                    if (mounted) setState(() {});
                  }
                : null,
          );
        },
      ));
    }
    widgets
      ..add(const SizedBox(height: 12))
      ..add(TextButton.icon(
        onPressed: () => context.push('/report', extra: {
          'targetType': 'user',
          'targetId': _otherId,
          'label': _iAmDonor ? 'the requester' : 'the donor',
        }),
        icon: const Icon(Icons.flag_outlined, size: 18),
        label: Text('Report ${_iAmDonor ? 'requester' : 'donor'}'),
      ));
    return widgets;
  }
}

class _PersonCard extends StatefulWidget {
  final String userId;
  final String label;
  final bool showContact;

  const _PersonCard({
    required this.userId,
    required this.label,
    required this.showContact,
  });

  @override
  State<_PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends State<_PersonCard> {
  late final Stream<AppUser?> _user = Dependencies.users.watchUser(widget.userId);

  String get label => widget.label;
  bool get showContact => widget.showContact;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _user,
      builder: (context, snapshot) {
        final u = snapshot.data;
        final name = u?.displayName ?? 'Shareloop member';
        final phone = u?.phone;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderPrimary),
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
                    Text(label,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (u != null) Text(u.district,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    if (showContact && phone != null && phone.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SelectableText(
                          '📞 ${Formatters.phone(phone)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandPrimary),
                        ),
                      ),
                    if (!showContact)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('Contact details appear once the request is accepted.',
                            style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
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
