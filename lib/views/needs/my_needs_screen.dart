import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../config/dependencies.dart';
import '../../l10n/app_localizations.dart';
import '../../models/need.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/need_card.dart';

class MyNeedsScreen extends StatefulWidget {
  const MyNeedsScreen({super.key});

  @override
  State<MyNeedsScreen> createState() => _MyNeedsScreenState();
}

class _MyNeedsScreenState extends State<MyNeedsScreen> {
  late final Stream<List<Need>> _needs = Dependencies.needs.myNeeds();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('My needs')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/need/new'),
        icon: const Icon(Icons.add),
        label: Text(t.postNeed),
      ),
      body: StreamBuilder<List<Need>>(
        stream: _needs,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(snapshot.error);
          if (!snapshot.hasData) return const LoadingView();
          final needs = snapshot.data!;
          if (needs.isEmpty) {
            return const EmptyState(
              icon: Icons.campaign_outlined,
              title: 'You haven\'t posted any needs',
              message: 'Tell donors what you need and why — they may have it.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: needs.length,
            itemBuilder: (context, i) => NeedCard(need: needs[i]),
          );
        },
      ),
    );
  }
}
