// Explore: Giveaways (items) and Needs (request posts), with search and
// category / condition / district filters + "near me" (GPS → district).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../config/dependencies.dart';
import '../../controllers/item_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/item.dart';
import '../../models/need.dart';
import '../../utils/formatters.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/need_card.dart';

class ExploreScreen extends StatefulWidget {
  final String? initialCategory;
  final String initialQuery;

  const ExploreScreen({
    super.key,
    this.initialCategory,
    this.initialQuery = '',
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final TextEditingController _search;
  final Stream<List<Item>> _items = Dependencies.items.availableItems();
  final Stream<List<Need>> _needs = Dependencies.needs.openNeeds();
  String? _category;
  String? _condition;
  String? _district;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery);
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickDistrict() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('All districts'),
              onTap: () => Navigator.of(ctx).pop(''),
            ),
            for (final d in AppDistricts.all)
              ListTile(
                title: Text(d),
                trailing: d == _district
                    ? const Icon(Icons.check, color: AppColors.brandPrimary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(d),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _district = picked.isEmpty ? null : picked);
  }

  Future<void> _nearMe() async {
    setState(() => _locating = true);
    try {
      final district = await Dependencies.users.detectNearestDistrict();
      if (!mounted) return;
      setState(() => _district = district);
      showSnack(context, 'Showing items in $district');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.navExplore,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: t.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(_search.clear),
                          ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _chip('All', _category == null, () => setState(() => _category = null)),
                for (final c in AppCategories.all)
                  _chip(c.name, _category == c.id,
                      () => setState(() => _category = _category == c.id ? null : c.id)),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                ActionChip(
                  avatar: _locating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 16),
                  label: Text(t.useMyLocation),
                  onPressed: _locating ? null : _nearMe,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.location_on_outlined, size: 16),
                  label: Text(_district ?? 'Any district'),
                  onPressed: _pickDistrict,
                ),
                const SizedBox(width: 8),
                for (final entry in AppConditions.labels.entries)
                  _chip(entry.value, _condition == entry.key,
                      () => setState(() => _condition = _condition == entry.key ? null : entry.key)),
              ],
            ),
          ),
          TabBar(
            labelColor: AppColors.brandPrimary,
            indicatorColor: AppColors.brandPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [Tab(text: t.giveaways), Tab(text: t.needs)],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _giveawaysTab(),
                _needsTab(t),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _giveawaysTab() {
    return StreamBuilder<List<Item>>(
      stream: _items,
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorView(snapshot.error);
        if (!snapshot.hasData) return const LoadingView();
        final items = Dependencies.items.filter(
          snapshot.data!,
          ItemFilter(
            query: _search.text,
            categoryId: _category,
            condition: _condition,
            district: _district,
          ),
        );
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No items found',
            message: 'Try another search or clear the filters.',
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 600 ? 3 : 2;
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) => _ExploreTile(item: items[index]),
            );
          },
        );
      },
    );
  }

  Widget _needsTab(AppLocalizations t) {
    return StreamBuilder<List<Need>>(
      stream: _needs,
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorView(snapshot.error);
        if (!snapshot.hasData) return const LoadingView();
        final needs = Dependencies.needs.filter(
          snapshot.data!,
          query: _search.text,
          categoryId: _category,
          district: _district,
        );
        if (needs.isEmpty) {
          return EmptyState(
            icon: Icons.campaign_outlined,
            title: 'No open needs here',
            message: 'People post what they need with a reason. Post your own need too.',
            action: OutlinedButton(
              onPressed: () => context.push('/need/new'),
              child: Text(t.postNeed),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: needs.length,
          itemBuilder: (context, i) => NeedCard(need: needs[i]),
        );
      },
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.tertiary,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? AppColors.brandPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ExploreTile extends StatelessWidget {
  final Item item;

  const _ExploreTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/item/${item.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderPrimary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ItemImage(
                url: item.images.isEmpty ? null : item.images.first,
                categoryId: item.categoryId,
                height: double.infinity,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.district,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${AppConditions.label(item.condition)} · ${Formatters.timeAgo(item.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
