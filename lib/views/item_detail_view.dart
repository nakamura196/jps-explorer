import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/jps_item.dart';
import '../providers/app_providers.dart';
import '../services/label_service.dart';

class ItemDetailView extends ConsumerStatefulWidget {
  final JpsItem item;

  const ItemDetailView({super.key, required this.item});

  @override
  ConsumerState<ItemDetailView> createState() => _ItemDetailViewState();
}

class _ItemDetailViewState extends ConsumerState<ItemDetailView> {
  List<JpsItem>? _similarItems;
  bool _loadingSimilar = false;
  String? _dbLabel;
  String? _orgLabel;
  String? _rightsLabel;

  bool _labelsResolved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_labelsResolved) {
      _labelsResolved = true;
      _resolveLabels();
      // Index in Spotlight for search
      ref.read(spotlightServiceProvider).indexItem(widget.item);
    }
  }

  Future<void> _resolveLabels() async {
    final labelService = ref.read(labelServiceProvider);
    final lang = Localizations.localeOf(context).languageCode;

    final db = await labelService.databaseLabel(widget.item.database, lang);
    final org = await labelService.organizationLabel(widget.item.organization, lang);
    final rights = LabelService.rightsLabel(widget.item.rights, lang);

    if (mounted) {
      setState(() {
        _dbLabel = db;
        _orgLabel = org;
        _rightsLabel = rights;
      });
    }
  }

  Future<void> _loadSimilarImages() async {
    setState(() => _loadingSimilar = true);
    try {
      final api = ref.read(jpsApiProvider);
      final result = await api.searchSimilarImages(itemId: widget.item.id);
      if (mounted) {
        setState(() {
          _similarItems = result.items;
          _loadingSimilar = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSimilar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.any((e) => e.id == widget.item.id);
    final shareUrl = widget.item.sourceUrl ??
        'https://jpsearch.go.jp/item/${widget.item.id}';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.itemDetail),
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : null),
            tooltip: isFav ? l10n.removeFavorite : l10n.addFavorite,
            onPressed: () {
              HapticFeedback.mediumImpact();
              final wasF = ref.read(favoritesProvider.notifier).isFavorite(widget.item.id);
              ref.read(favoritesProvider.notifier).toggle(widget.item);
              final spotlight = ref.read(spotlightServiceProvider);
              if (wasF) {
                spotlight.removeItem(widget.item.id);
              } else {
                spotlight.indexItem(widget.item);
              }
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.share),
              tooltip: l10n.share,
              onPressed: () {
                final box = context.findRenderObject() as RenderBox?;
                Share.share(
                  '${widget.item.title}\n$shareUrl',
                  sharePositionOrigin:
                      box != null ? box.localToGlobal(Offset.zero) & box.size : null,
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'item_${widget.item.id}',
              child: SizedBox(
                height: 300,
                child: widget.item.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.item.thumbnailUrl!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (_, __, ___) =>
                            const Center(child: Icon(Icons.broken_image, size: 64)),
                      )
                    : const Center(child: Icon(Icons.image, size: 64)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (widget.item.description != null) ...[
                    const SizedBox(height: 12),
                    Text(_stripHtml(widget.item.description!)),
                  ],
                  const SizedBox(height: 16),
                  _buildInfoRow(context, l10n.filterType, widget.item.type),
                  _buildInfoRow(context, l10n.eraSlider, widget.item.temporal),
                  _buildInfoRow(context, l10n.nearbyItems, widget.item.spatial),
                  _buildInfoRow(context, l10n.source,
                      _orgLabel ?? widget.item.organization),
                  _buildInfoRow(context, l10n.database,
                      _dbLabel ?? widget.item.database),
                  _buildInfoRow(context, l10n.filterRights,
                      _rightsLabel ?? widget.item.rights),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(shareUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: Text(l10n.viewOriginal),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _loadingSimilar ? null : _loadSimilarImages,
                        icon: _loadingSimilar
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.image_search),
                        label: Text(l10n.similarImages),
                      ),
                    ],
                  ),
                  if (_similarItems != null && _similarItems!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.similarImages,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _similarItems!.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final similar = _similarItems![index];
                          return SizedBox(
                            width: 120,
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ItemDetailView(item: similar),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: similar.thumbnailUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: similar.thumbnailUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) =>
                                                  const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                              errorWidget: (_, __, ___) =>
                                                  const Center(
                                                child:
                                                    Icon(Icons.broken_image),
                                              ),
                                            )
                                          : const Center(
                                              child:
                                                  Icon(Icons.image, size: 32),
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Text(
                                        similar.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  Widget _buildInfoRow(BuildContext context, String label, String? value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
