import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../services/tip_jar_service.dart';

class TipJarView extends ConsumerStatefulWidget {
  const TipJarView({super.key});

  @override
  ConsumerState<TipJarView> createState() => _TipJarViewState();
}

class _TipJarViewState extends ConsumerState<TipJarView> {
  final TipJarService _service = TipJarService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    _service.initialize();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _service.dispose();
    super.dispose();
  }

  static const _emojis = ['☕', '🍰', '🎉'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final tipNames = [l10n.tipSmall, l10n.tipMedium, l10n.tipLarge];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tipJar),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          // Description
          Text(
            l10n.tipJarDescription,
            style: TextStyle(color: theme.colorScheme.secondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Products
          if (_service.state == TipJarState.loading)
            const Center(child: CircularProgressIndicator())
          else if (_service.products.isEmpty &&
              _service.state != TipJarState.error)
            ...List.generate(3, (index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading:
                      Text(_emojis[index], style: const TextStyle(fontSize: 28)),
                  title: Text(tipNames[index]),
                  enabled: false,
                ),
              );
            })
          else
            ..._service.products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              final emoji = index < _emojis.length ? _emojis[index] : '💰';
              final name = index < tipNames.length ? tipNames[index] : product.title;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(emoji, style: const TextStyle(fontSize: 28)),
                  title: Text(name),
                  subtitle: Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  trailing: Text(
                    product.price,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  enabled: _service.state != TipJarState.purchasing,
                  onTap: () => _service.purchase(product),
                ),
              );
            }),

          const SizedBox(height: 16),

          // Purchasing indicator
          if (_service.state == TipJarState.purchasing)
            const Center(child: CircularProgressIndicator()),

          // Success message
          if (_service.state == TipJarState.success) ...[
            const Icon(Icons.favorite, size: 32, color: Colors.pink),
            const SizedBox(height: 8),
            Text(
              l10n.tipThankYou,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],

          // Error message (show as info, not error)
          if (_service.state == TipJarState.error)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.outline),
                    const SizedBox(height: 8),
                    Text(
                      'チップ機能は現在準備中です。',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
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
