import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../models/jps_item.dart';
import '../providers/app_providers.dart';
import 'item_detail_view.dart';

class CameraSearchView extends ConsumerStatefulWidget {
  const CameraSearchView({super.key});

  @override
  ConsumerState<CameraSearchView> createState() => _CameraSearchViewState();
}

class _CameraSearchViewState extends ConsumerState<CameraSearchView> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();

  File? _imageFile;
  bool _isSearchingByImage = false;
  List<JpsItem>? _imageSearchResults;
  int? _imageSearchHits;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (pickedFile == null) return;

      setState(() {
        _imageFile = File(pickedFile.path);
        _imageSearchResults = null;
        _imageSearchHits = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorOccurred)),
        );
      }
    }
  }

  Future<void> _searchByImage() async {
    if (_imageFile == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSearchingByImage = true);

    try {
      final bytes = await _imageFile!.readAsBytes();
      final ext = _imageFile!.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

      final api = ref.read(jpsApiProvider);
      final result = await api.searchByImageBytes(
        imageBytes: Uint8List.fromList(bytes),
        mimeType: mimeType,
        size: 20,
      );

      if (mounted) {
        setState(() {
          _imageSearchResults = result.items;
          _imageSearchHits = result.totalHits;
          _isSearchingByImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearchingByImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _searchWithText() {
    final query = _textController.text.trim();
    if (query.isEmpty) return;

    HapticFeedback.mediumImpact();
    ref.read(exploreSearchTypeProvider.notifier).state =
        ExploreSearchType.keyword;
    ref.read(exploreQueryProvider.notifier).state = query;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cameraSearch)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 撮影画像プレビュー
                  if (_imageFile != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _imageFile!,
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 画像で類似検索ボタン
                    FilledButton.icon(
                      onPressed: _isSearchingByImage ? null : _searchByImage,
                      icon: _isSearchingByImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.image_search),
                      label: Text(l10n.similarImages),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 類似画像検索結果
                  if (_imageSearchResults != null) ...[
                    Text(
                      '${l10n.similarImages} (${l10n.itemCount(_imageSearchHits ?? 0)})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_imageSearchResults!.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(l10n.noResults),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: _imageSearchResults!.length,
                        itemBuilder: (context, index) {
                          final item = _imageSearchResults![index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ItemDetailView(item: item),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: item.thumbnailUrl != null
                                        ? Image.network(
                                            item.thumbnailUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.broken_image),
                                          )
                                        : const Icon(Icons.image),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const Divider(height: 32),
                  ],

                  // テキスト検索セクション
                  TextField(
                    controller: _textController,
                    maxLines: null,
                    minLines: 2,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: l10n.searchKeyword,
                      labelText: l10n.searchKeyword,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: _textController.text.trim().isEmpty
                        ? null
                        : _searchWithText,
                    child: Text(l10n.searchWithText),
                  ),

                  // プレースホルダー
                  if (_imageFile == null) ...[
                    const SizedBox(height: 48),
                    Icon(
                      Icons.document_scanner_outlined,
                      size: 64,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.cameraSearch,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colorScheme.outline,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 下部ボタン
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSearchingByImage
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: Text(l10n.takePhoto),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSearchingByImage
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: Text(l10n.pickFromGallery),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
