import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_providers.dart';
import '../models/jps_item.dart';
import 'item_detail_view.dart';

class GalleryView extends ConsumerWidget {
  const GalleryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final galleriesAsync = ref.watch(galleryListProvider);

    return galleriesAsync.when(
      data: (galleries) {
        if (galleries.isEmpty) {
          return Center(child: Text(l10n.noResults));
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(galleryListProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: galleries.length,
            itemBuilder: (context, index) {
              final gallery = galleries[index];
              return _GalleryCard(gallery: gallery);
            },
          ),
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
              onPressed: () => ref.invalidate(galleryListProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryCard extends ConsumerWidget {
  final JpsGallery gallery;

  const _GalleryCard({required this.gallery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showGalleryDetail(context, ref),
        child: SizedBox(
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (gallery.imageUrl != null)
                CachedNetworkImage(
                  imageUrl: gallery.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image)),
                )
              else
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(child: Icon(Icons.collections, size: 48)),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gallery.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (gallery.summary != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        gallery.summary!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGalleryDetail(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _GalleryDetailPage(gallery: gallery),
      ),
    );
  }
}

class _GalleryDetailPage extends ConsumerStatefulWidget {
  final JpsGallery gallery;

  const _GalleryDetailPage({required this.gallery});

  @override
  ConsumerState<_GalleryDetailPage> createState() =>
      _GalleryDetailPageState();
}

class _GalleryDetailPageState extends ConsumerState<_GalleryDetailPage> {
  List<JpsItem>? _items;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGalleryItems();
  }

  Future<void> _loadGalleryItems() async {
    try {
      final api = ref.read(jpsApiProvider);
      final data = await api.getGallery(widget.gallery.id);

      // アイテムIDを parts と subPages から再帰的に収集
      final itemIds = <String>[];
      _collectItemIds(data['parts'], itemIds);
      _collectItemIds(data['subPages'], itemIds);

      // 各アイテムの詳細を並列で取得（最大20件）
      final futures = itemIds.take(20).map((id) async {
        try {
          return await api.getItem(id);
        } catch (_) {
          return null;
        }
      });
      final results = await Future.wait(futures);
      final items = results.whereType<JpsItem>().toList();

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _collectItemIds(dynamic parts, List<String> ids) {
    if (parts is! List) return;
    for (final part in parts) {
      if (part is! Map<String, dynamic>) continue;
      final type = part['type']?.toString() ?? '';

      // list-item タイプからIDを取得
      if (type == 'jps-curation-list-item') {
        final id = part['id']?.toString();
        if (id != null && id.isNotEmpty && !ids.contains(id)) {
          ids.add(id);
        }
      }

      // id フィールドがあり、JPS アイテムIDに見える場合（type不問）
      if (type.isEmpty || type.contains('item')) {
        final id = part['id']?.toString();
        if (id != null && id.contains('-') && !type.contains('section') &&
            !type.contains('text') && !type.contains('index') &&
            !type.contains('list') && !ids.contains(id)) {
          ids.add(id);
        }
      }

      // 再帰的にネストされた parts / items を探索
      if (part.containsKey('parts')) {
        _collectItemIds(part['parts'], ids);
      }
      if (part.containsKey('items')) {
        _collectItemIds(part['items'], ids);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(widget.gallery.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.errorOccurred),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _loadGalleryItems();
                        },
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : _items == null || _items!.isEmpty
                  ? Center(child: Text(l10n.noResults))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _items!.length,
                      itemBuilder: (context, index) {
                        final item = _items![index];
                        return Card(
                          child: ListTile(
                            leading: SizedBox(
                              width: 56,
                              height: 56,
                              child: item.thumbnailUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: item.thumbnailUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (_, __, ___) =>
                                          const Icon(Icons.broken_image),
                                    )
                                  : const Icon(Icons.image, size: 40),
                            ),
                            title: Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: item.type != null
                                ? Text(
                                    item.type!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ItemDetailView(item: item),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
