import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/jps_item.dart';

class JpsApiService {
  static const _baseUrl = 'https://jpsearch.go.jp/api';

  final http.Client _client;

  JpsApiService({http.Client? client}) : _client = client ?? http.Client();

  /// キーワード検索
  Future<JpsSearchResult> searchItems({
    String? keyword,
    int size = 20,
    int from = 0,
    String? filterType,
    String? filterRights,
  }) async {
    final params = <String, String>{
      'size': size.toString(),
      'from': from.toString(),
    };
    if (keyword != null && keyword.isNotEmpty) {
      params['keyword'] = keyword;
    }
    if (filterType != null) params['f-type'] = filterType;
    if (filterRights != null) params['f-rights'] = filterRights;

    return _searchItems(params);
  }

  /// モチーフ検索（テキスト → 画像）
  Future<JpsSearchResult> searchByMotif({
    required String motif,
    int size = 20,
    int from = 0,
  }) async {
    return _searchItems({
      'text2image': motif,
      'size': size.toString(),
      'from': from.toString(),
    });
  }

  /// 類似画像検索
  Future<JpsSearchResult> searchSimilarImages({
    required String itemId,
    int size = 20,
    int from = 0,
  }) async {
    return _searchItems({
      'image': itemId,
      'size': size.toString(),
      'from': from.toString(),
    });
  }

  /// 時代で検索
  Future<JpsSearchResult> searchByEra({
    required int startYear,
    required int endYear,
    String? keyword,
    int size = 20,
    int from = 0,
  }) async {
    final params = <String, String>{
      'r-tempo': '$startYear,$endYear',
      'size': size.toString(),
      'from': from.toString(),
    };
    if (keyword != null && keyword.isNotEmpty) {
      params['keyword'] = keyword;
    }
    return _searchItems(params);
  }

  /// 場所で検索（緯度・経度・半径）
  Future<JpsSearchResult> searchByLocation({
    required double latitude,
    required double longitude,
    String radius = '10km',
    String? keyword,
    int size = 20,
    int from = 0,
  }) async {
    final params = <String, String>{
      'g-coordinates': '$latitude,$longitude,$radius',
      'size': size.toString(),
      'from': from.toString(),
    };
    if (keyword != null && keyword.isNotEmpty) {
      params['keyword'] = keyword;
    }
    return _searchItems(params);
  }

  /// 画像ファイルのバイト列で類似画像検索
  Future<JpsSearchResult> searchByImageBytes({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    int size = 20,
    int from = 0,
  }) async {
    // Step 1: Base64エンコードして特徴量を取得
    final b64 = 'data:$mimeType;base64,${base64Encode(imageBytes)}';
    final featuresResponse = await _client.post(
      Uri.parse('https://jpsearch.go.jp/dl/api/imagefeatures/'),
      headers: {
        'Content-Type': 'application/json',
        'Origin': 'https://jpsearch.go.jp',
      },
      body: jsonEncode({'img_b64': b64}),
    );
    if (featuresResponse.statusCode != 200) {
      throw Exception('Failed to extract image features: ${featuresResponse.statusCode}');
    }
    final featuresJson = jsonDecode(featuresResponse.body) as Map<String, dynamic>;
    final features = featuresJson['body'] as List;

    // Step 2: 特徴量を送信してIDを取得
    final featureIdResponse = await _client.post(
      Uri.parse('$_baseUrl/item/create-image-feature'),
      headers: {
        'Content-Type': 'application/json',
        'Origin': 'https://jpsearch.go.jp',
        'X-Requested-With': 'XmlHttpRequest',
        'Referer': 'https://jpsearch.go.jp/csearch/jps-image',
      },
      body: jsonEncode(features),
    );
    if (featureIdResponse.statusCode != 200) {
      throw Exception('Failed to create image feature: ${featureIdResponse.statusCode}');
    }
    final featureId = featureIdResponse.body.trim();

    // Step 3: IDで類似画像検索
    return searchSimilarImages(itemId: featureId, size: size, from: from);
  }

  /// アイテム詳細取得
  Future<JpsItem> getItem(String itemId) async {
    final url = Uri.parse('$_baseUrl/item/$itemId');
    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to get item: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return JpsItem.fromSearchResult(json);
  }

  /// ギャラリー検索
  Future<List<JpsGallery>> searchGalleries({
    String? keyword,
    int size = 20,
    int from = 0,
  }) async {
    final params = <String, String>{
      'size': size.toString(),
      'from': from.toString(),
    };
    if (keyword != null && keyword.isNotEmpty) {
      params['keyword'] = keyword;
    }

    final url =
        Uri.parse('$_baseUrl/curation/search').replace(queryParameters: params);
    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw Exception('Gallery search failed: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['list'] as List? ?? [];
    return list
        .map((e) => JpsGallery.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// ギャラリー詳細取得
  Future<Map<String, dynamic>> getGallery(String galleryId) async {
    final url = Uri.parse('$_baseUrl/curation/$galleryId');
    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to get gallery: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<JpsSearchResult> _searchItems(Map<String, String> params) async {
    final url = Uri.parse('$_baseUrl/item/search/jps-cross')
        .replace(queryParameters: params);
    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw Exception('Search failed: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['list'] as List? ?? [];
    final hit = json['hit'] as int? ?? 0;

    final items = list
        .map((e) => JpsItem.fromSearchResult(e as Map<String, dynamic>))
        .toList();

    Map<String, List<FacetEntry>>? facets;
    final facetData = json['facets'] as List?;
    if (facetData != null) {
      facets = {};
      for (final f in facetData) {
        final facet = f as Map<String, dynamic>;
        final name = facet['name']?.toString() ?? '';
        final entries = (facet['list'] as List? ?? [])
            .map((e) {
              final entry = e as Map<String, dynamic>;
              return FacetEntry(
                key: entry['key']?.toString() ?? '',
                count: entry['count'] as int? ?? 0,
              );
            })
            .toList();
        facets[name] = entries;
      }
    }

    return JpsSearchResult(items: items, totalHits: hit, facets: facets);
  }
}
