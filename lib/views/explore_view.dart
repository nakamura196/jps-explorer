import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_providers.dart';
import 'item_detail_view.dart';
import 'daily_pick_card.dart';

class ExploreView extends ConsumerStatefulWidget {
  const ExploreView({super.key});

  @override
  ConsumerState<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends ConsumerState<ExploreView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      HapticFeedback.lightImpact();
      ref.read(exploreQueryProvider.notifier).state = query;
    }
  }

  void _searchSample(String query) {
    HapticFeedback.lightImpact();
    _searchController.text = query;
    ref.read(exploreQueryProvider.notifier).state = query;
  }

  Widget _buildSampleChips(BuildContext context) {
    final searchType = ref.watch(exploreSearchTypeProvider);
    final samples = searchType == ExploreSearchType.motif
        ? ['鶴', '富士山', '桜', '龍', '虎', '波', '月', '松', '馬', '城']
        : ['浮世絵', '古地図', '源氏物語', '東海道', '屏風', '刀剣', '仏像', '茶道具'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const DailyPickCard(),
          const SizedBox(height: 24),
          Icon(
            Icons.image_search,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: samples.map((s) {
              return ActionChip(
                label: Text(s),
                onPressed: () => _searchSample(s),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchType = ref.watch(exploreSearchTypeProvider);
    final resultAsync = ref.watch(exploreResultProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: searchType == ExploreSearchType.motif
                      ? l10n.searchHint
                      : l10n.searchKeyword,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(exploreQueryProvider.notifier).state = '';
                            setState(() {});
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _onSubmit,
                      ),
                    ],
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _onSubmit(),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ExploreSearchType>(
                segments: [
                  ButtonSegment(
                    value: ExploreSearchType.motif,
                    label: Text(l10n.searchHint.split('(').first.trim()),
                    icon: const Icon(Icons.image_search),
                  ),
                  ButtonSegment(
                    value: ExploreSearchType.keyword,
                    label: Text(l10n.searchKeyword),
                    icon: const Icon(Icons.text_fields),
                  ),
                ],
                selected: {searchType},
                onSelectionChanged: (selected) {
                  ref.read(exploreSearchTypeProvider.notifier).state =
                      selected.first;
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: resultAsync.when(
            data: (result) {
              if (result == null) {
                return _buildSampleChips(context);
              }
              if (result.items.isEmpty) {
                return Center(child: Text(l10n.noResults));
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.itemCount(result.totalHits),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: result.items.length,
                      itemBuilder: (context, index) {
                        final item = result.items[index];
                        return _ExploreGridItem(item: item);
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.errorOccurred),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => ref.invalidate(exploreResultProvider),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExploreGridItem extends ConsumerWidget {
  final dynamic item;

  const _ExploreGridItem({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ItemDetailView(item: item)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                onLongPress: () {
                  ref.read(similarItemIdProvider.notifier).state = item.id;
                  _showSimilarImagesSheet(context, ref);
                },
                child: item.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image),
                        ),
                      )
                    : const Center(child: Icon(Icons.image, size: 48)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSimilarImagesSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final similarAsync = ref.watch(similarResultProvider);
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.8,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.similarImages,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: similarAsync.when(
                        data: (result) {
                          if (result == null || result.items.isEmpty) {
                            return Center(child: Text(l10n.noResults));
                          }
                          return GridView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: result.items.length,
                            itemBuilder: (context, index) {
                              final similarItem = result.items[index];
                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ItemDetailView(
                                          item: similarItem,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: similarItem.thumbnailUrl != null
                                            ? CachedNetworkImage(
                                                imageUrl:
                                                    similarItem.thumbnailUrl!,
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) =>
                                                    const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                                errorWidget: (_, __, ___) =>
                                                    const Center(
                                                  child: Icon(
                                                      Icons.broken_image),
                                                ),
                                              )
                                            : const Center(
                                                child: Icon(Icons.image,
                                                    size: 48),
                                              ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          similarItem.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) =>
                            Center(child: Text(l10n.errorOccurred)),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
