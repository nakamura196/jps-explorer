import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_providers.dart';
import 'tip_jar_view.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentTheme = ref.watch(appThemeProvider);
    final currentLanguage = ref.watch(appLanguageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.theme, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<AppTheme>(
            segments: [
              ButtonSegment(
                value: AppTheme.system,
                label: Text(l10n.themeSystem),
              ),
              ButtonSegment(
                value: AppTheme.light,
                label: Text(l10n.themeLight),
              ),
              ButtonSegment(
                value: AppTheme.dark,
                label: Text(l10n.themeDark),
              ),
            ],
            selected: {currentTheme},
            onSelectionChanged: (selected) {
              saveTheme(ref, selected.first);
            },
          ),
          const SizedBox(height: 24),
          Text(l10n.language, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String?>(
            segments: [
              ButtonSegment(
                value: null,
                label: Text(l10n.themeSystem),
              ),
              const ButtonSegment(
                value: 'en',
                label: Text('English'),
              ),
              const ButtonSegment(
                value: 'ja',
                label: Text('Japanese'),
              ),
            ],
            selected: {currentLanguage},
            onSelectionChanged: (selected) {
              saveLanguage(ref, selected.first);
            },
          ),
          const SizedBox(height: 24),
          Text(l10n.nearbyItems,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _NearbyNotificationTile(),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Text('☕', style: TextStyle(fontSize: 24)),
              title: Text(l10n.tipJar),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TipJarView()),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.about, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse('https://jpsearch.go.jp');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Japan Search'),
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

class _NearbyNotificationTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(nearbyEnabledProvider);
    final service = ref.read(nearbyNotificationProvider);

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('通知'),
            subtitle: Text(isEnabled
                ? '移動時に近くの文化資源を通知します'
                : 'オフ'),
            value: isEnabled,
            onChanged: (value) async {
              if (value) {
                final granted = await service.requestPermissions();
                if (!granted) return;
              }
              await service.setEnabled(value);
              ref.read(nearbyEnabledProvider.notifier).state = value;
            },
          ),
          if (isEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '1km', label: Text('1km')),
                  ButtonSegment(value: '5km', label: Text('5km')),
                  ButtonSegment(value: '10km', label: Text('10km')),
                ],
                selected: {service.radius},
                onSelectionChanged: (selected) {
                  service.setRadius(selected.first);
                },
              ),
            ),
        ],
      ),
    );
  }
}
