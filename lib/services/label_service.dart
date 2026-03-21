import 'dart:convert';
import 'package:http/http.dart' as http;

class LabelService {
  static const _baseUrl = 'https://jpsearch.go.jp/api';

  final http.Client _client;
  final Map<String, Map<String, String>> _dbCache = {};
  final Map<String, Map<String, String>> _orgCache = {};

  LabelService({http.Client? client}) : _client = client ?? http.Client();

  /// 利用条件IDをラベルに変換（固定マッピング）
  static String rightsLabel(String? id, String lang) {
    if (id == null || id.isEmpty) return '';
    final labels = _rightsLabels[id.toLowerCase()];
    if (labels == null) return id;
    return lang == 'ja' ? labels['ja']! : labels['en']!;
  }

  /// データベースIDからラベルを取得（APIキャッシュ付き）
  Future<String> databaseLabel(String? id, String lang) async {
    if (id == null || id.isEmpty) return '';
    if (_dbCache.containsKey(id)) {
      return _dbCache[id]![lang] ?? _dbCache[id]!['ja'] ?? id;
    }
    try {
      final url = Uri.parse('$_baseUrl/database/$id');
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final name = json['name'];
        if (name is Map) {
          _dbCache[id] = {
            'ja': name['ja']?.toString() ?? id,
            'en': name['en']?.toString() ?? name['ja']?.toString() ?? id,
          };
          return _dbCache[id]![lang] ?? id;
        }
      }
    } catch (_) {}
    return id;
  }

  /// 機関IDからラベルを取得（APIキャッシュ付き）
  Future<String> organizationLabel(String? id, String lang) async {
    if (id == null || id.isEmpty) return '';
    if (_orgCache.containsKey(id)) {
      return _orgCache[id]![lang] ?? _orgCache[id]!['ja'] ?? id;
    }
    try {
      final url = Uri.parse('$_baseUrl/organization/$id');
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final name = json['name'];
        if (name is Map) {
          _orgCache[id] = {
            'ja': name['ja']?.toString() ?? id,
            'en': name['en']?.toString() ?? name['ja']?.toString() ?? id,
          };
          return _orgCache[id]![lang] ?? id;
        }
      }
    } catch (_) {}
    return id;
  }

  static const _rightsLabels = {
    'pdm': {'ja': 'パブリック・ドメイン', 'en': 'Public Domain Mark'},
    'cc0': {'ja': 'CC0（パブリック・ドメイン）', 'en': 'CC0 (Public Domain)'},
    'ccby': {'ja': 'CC BY（表示）', 'en': 'CC BY (Attribution)'},
    'ccbysa': {'ja': 'CC BY-SA（表示-継承）', 'en': 'CC BY-SA'},
    'ccbynd': {'ja': 'CC BY-ND（表示-改変禁止）', 'en': 'CC BY-ND'},
    'ccbync': {'ja': 'CC BY-NC（表示-非営利）', 'en': 'CC BY-NC'},
    'ccbyncsa': {'ja': 'CC BY-NC-SA（表示-非営利-継承）', 'en': 'CC BY-NC-SA'},
    'ccbyncnd': {'ja': 'CC BY-NC-ND（表示-非営利-改変禁止）', 'en': 'CC BY-NC-ND'},
    'incr_edu': {'ja': '教育利用可', 'en': 'Educational Use'},
    'incr_noncom': {'ja': '非営利利用可', 'en': 'Non-Commercial Use'},
    'incr_com': {'ja': '商用利用可', 'en': 'Commercial Use'},
    'unknown': {'ja': '不明', 'en': 'Unknown'},
  };
}
