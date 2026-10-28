// Requests tab: "Received" (people asking for my items) and "Sent" (my asks).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/request.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/request_card.dart';
import '../../config/dependencies.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              AppLocalizations.of(context)!.navRequests,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TabBar(
            labelColor: AppColors.brandPrimary,
            indicatorColor: AppColors.brandPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.received),
              Tab(text: AppLocalizations.of(context)!.sent),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _RequestList(
                  streamFactory: Dependencies.requests.receivedRequests,
                  incoming: true,
                  emptyTitle: 'No requests for your items yet',
                  emptyMessage: 'When someone asks for an item you shared, it shows up here.',
                ),
                _RequestList(
                  streamFactory: Dependencies.requests.sentRequests,
                  incoming: false,
                  emptyTitle: 'You haven\'t requested anything',
                  emptyMessage: 'Find something you need in Explore and tap Request.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestList extends StatefulWidget {
  final Stream<List<ShareRequest>> Function() streamFactory;
  final bool incoming;
  final String emptyTitle;
  final String emptyMessage;

  const _RequestList({
    required this.streamFactory,
    required this.incoming,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  @override
  State<_RequestList> createState() => _RequestListState();
}

class _RequestListState extends State<_RequestList>
    with AutomaticKeepAliveClientMixin {
  late final Stream<List<ShareRequest>> _stream = widget.streamFactory();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<ShareRequest>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorView(snapshot.error);
        if (!snapshot.hasData) return const LoadingView();
        final list = snapshot.data!;
        if (list.isEmpty) {
          return EmptyState(
            icon: widget.incoming ? Icons.move_to_inbox_outlined : Icons.outbox_outlined,
            title: widget.emptyTitle,
            message: widget.emptyMessage,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: list.length,
          itemBuilder: (context, i) => RequestCard(
            request: list[i],
            incoming: widget.incoming,
            onTap: () => context.push('/request/${list[i].id}'),
          ),
        );
      },
    );
  }
}
