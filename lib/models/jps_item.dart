class JpsItem {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? sourceUrl;
  final String? database;
  final String? organization;
  final String? type;
  final String? rights;
  final String? temporal;
  final String? spatial;
  final double? latitude;
  final double? longitude;

  const JpsItem({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.sourceUrl,
    this.database,
    this.organization,
    this.type,
    this.rights,
    this.temporal,
    this.spatial,
    this.latitude,
    this.longitude,
  });

  factory JpsItem.fromSearchResult(Map<String, dynamic> json) {
    final common = json['common'] as Map<String, dynamic>? ?? {};

    String? thumbnail;
    final thumbnails = common['thumbnailUrl'];
    if (thumbnails is List && thumbnails.isNotEmpty) {
      thumbnail = thumbnails.first as String?;
    } else if (thumbnails is String) {
      thumbnail = thumbnails;
    }

    String? title;
    final titles = common['title'];
    if (titles is List && titles.isNotEmpty) {
      title = titles.first.toString();
    } else if (titles is String) {
      title = titles;
    }
    title ??= json['id']?.toString() ?? 'Unknown';

    String? description;
    final descriptions = common['description'];
    if (descriptions is List && descriptions.isNotEmpty) {
      description = descriptions.first.toString();
    } else if (descriptions is String) {
      description = descriptions;
    }

    String? sourceUrl;
    final urls = common['sourceUrl'];
    if (urls is List && urls.isNotEmpty) {
      sourceUrl = urls.first.toString();
    } else if (urls is String) {
      sourceUrl = urls;
    }

    String? type;
    final types = common['type'];
    if (types is List && types.isNotEmpty) {
      type = types.first.toString();
    } else if (types is String) {
      type = types;
    }

    String? temporal;
    final temporals = common['temporal'];
    if (temporals is List && temporals.isNotEmpty) {
      temporal = temporals.first.toString();
    } else if (temporals is String) {
      temporal = temporals;
    }

    String? spatial;
    final locations = common['location'];
    if (locations is List && locations.isNotEmpty) {
      spatial = locations.first.toString();
    } else if (locations is String) {
      spatial = locations;
    }
    if (spatial == null) {
      final spatials = common['spatial'];
      if (spatials is List && spatials.isNotEmpty) {
        spatial = spatials.first.toString();
      } else if (spatials is String) {
        spatial = spatials;
      }
    }

    double? lat;
    double? lng;

    // 1. Check common.coordinates (map with lat/lng)
    final coordinates = common['coordinates'];
    if (coordinates is Map) {
      lat = (coordinates['lat'] as num?)?.toDouble();
      lng = (coordinates['lon'] as num?)?.toDouble() ??
            (coordinates['lng'] as num?)?.toDouble();
    }

    // 2. Check common.spatial_coordinates ("lat,lng" string)
    if (lat == null || lng == null) {
      final spatialCoords = common['spatial_coordinates'];
      if (spatialCoords is String) {
        final parsed = _parseLatLngString(spatialCoords);
        if (parsed != null) {
          lat = parsed.$1;
          lng = parsed.$2;
        }
      }
    }

    // 3. Check rdfindex array for geo-related fields
    if (lat == null || lng == null) {
      final rdfindex = json['rdfindex'];
      if (rdfindex is List) {
        for (final entry in rdfindex) {
          if (entry is Map<String, dynamic>) {
            for (final key in entry.keys) {
              final lowerKey = key.toLowerCase();
              if (lowerKey.contains('geo:lat') ||
                  lowerKey.contains('schema:latitude') ||
                  lowerKey == 'latitude') {
                lat ??= _toDouble(entry[key]);
              }
              if (lowerKey.contains('geo:long') ||
                  lowerKey.contains('schema:longitude') ||
                  lowerKey == 'longitude') {
                lng ??= _toDouble(entry[key]);
              }
            }
            final geoVal = entry['geo'] ?? entry['geo:geometry'];
            if (geoVal is String && lat == null) {
              final parsed = _parseLatLngString(geoVal);
              if (parsed != null) {
                lat = parsed.$1;
                lng = parsed.$2;
              }
            }
          }
          if (lat != null && lng != null) break;
        }
      }
    }

    // 4. Try parsing spatial field for coordinate-like text
    if (lat == null || lng == null) {
      if (spatial is String) {
        final parsed = _parseLatLngString(spatial);
        if (parsed != null) {
          lat = parsed.$1;
          lng = parsed.$2;
        }
      }
    }

    return JpsItem(
      id: json['id']?.toString() ?? '',
      title: title,
      description: description,
      thumbnailUrl: thumbnail,
      sourceUrl: sourceUrl,
      database: common['database']?.toString() ?? json['database']?.toString(),
      organization: common['provider']?.toString() ??
          common['ownerOrg']?.toString() ??
          json['organization']?.toString(),
      type: type,
      rights: common['contentsRightsType']?.toString() ??
          common['rights']?.toString(),
      temporal: temporal,
      spatial: spatial,
      latitude: lat,
      longitude: lng,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'thumbnailUrl': thumbnailUrl,
        'sourceUrl': sourceUrl,
        'database': database,
        'organization': organization,
        'type': type,
        'rights': rights,
        'temporal': temporal,
        'spatial': spatial,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory JpsItem.fromJson(Map<String, dynamic> json) => JpsItem(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        sourceUrl: json['sourceUrl'] as String?,
        database: json['database'] as String?,
        organization: json['organization'] as String?,
        type: json['type'] as String?,
        rights: json['rights'] as String?,
        temporal: json['temporal'] as String?,
        spatial: json['spatial'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}

class JpsSearchResult {
  final List<JpsItem> items;
  final int totalHits;
  final Map<String, List<FacetEntry>>? facets;

  const JpsSearchResult({
    required this.items,
    required this.totalHits,
    this.facets,
  });
}

class FacetEntry {
  final String key;
  final int count;

  const FacetEntry({required this.key, required this.count});
}

class JpsGallery {
  final String id;
  final String title;
  final String? summary;
  final String? imageUrl;
  final List<String> tags;

  const JpsGallery({
    required this.id,
    required this.title,
    this.summary,
    this.imageUrl,
    this.tags = const [],
  });

  factory JpsGallery.fromJson(Map<String, dynamic> json) {
    final tags = <String>[];
    final tagList = json['tag'];
    if (tagList is List) {
      for (final t in tagList) {
        tags.add(t.toString());
      }
    }

    return JpsGallery(
      id: json['id']?.toString() ?? '',
      title: _extractLocalizedString(json['title']) ?? '',
      summary: _extractLocalizedString(json['summary']),
      imageUrl: _extractImageUrl(json['image']),
      tags: tags,
    );
  }

  static String? _extractLocalizedString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      return (value['ja'] ?? value['en'] ?? value.values.firstOrNull)
          ?.toString();
    }
    return value.toString();
  }

  static String? _extractImageUrl(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      final url = value['url'] ?? value['thumbnailUrl'];
      if (url is String) return url;
    }
    return null;
  }
}

/// Parses a string that may contain lat/lng coordinates.
/// Supports formats: "lat,lng", "lat lng", "lat, lng"
/// Returns (latitude, longitude) or null if parsing fails.
(double, double)? _parseLatLngString(String s) {
  // Try matching coordinate-like patterns
  final regex = RegExp(
    r'(-?\d{1,3}(?:\.\d+))\s*[,\s]\s*(-?\d{1,3}(?:\.\d+))',
  );
  final match = regex.firstMatch(s);
  if (match != null) {
    final a = double.tryParse(match.group(1)!);
    final b = double.tryParse(match.group(2)!);
    if (a != null && b != null) {
      // Validate reasonable lat/lng ranges
      if (a >= -90 && a <= 90 && b >= -180 && b <= 180) {
        return (a, b);
      }
      // Maybe reversed (lng, lat)
      if (b >= -90 && b <= 90 && a >= -180 && a <= 180) {
        return (b, a);
      }
    }
  }
  return null;
}

/// Safely converts a dynamic value to double.
double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  if (value is List && value.isNotEmpty) return _toDouble(value.first);
  return null;
}
