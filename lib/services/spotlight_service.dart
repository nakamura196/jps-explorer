import 'package:flutter/services.dart';
import '../models/jps_item.dart';

class SpotlightService {
  static const _channel = MethodChannel('com.nakamura196.jpsExplorer/spotlight');

  /// Index an item in Spotlight search
  Future<bool> indexItem(JpsItem item) async {
    try {
      final result = await _channel.invokeMethod('indexItem', {
        'id': item.id,
        'title': item.title,
        'description': item.description,
        'thumbnailUrl': item.thumbnailUrl,
        'keywords': [
          if (item.type != null) item.type!,
          if (item.temporal != null) item.temporal!,
          if (item.spatial != null) item.spatial!,
          'ジャパンサーチ',
          'Japan Search',
        ],
      });
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Remove an item from Spotlight
  Future<bool> removeItem(String itemId) async {
    try {
      final result = await _channel.invokeMethod('removeItem', itemId);
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Remove all indexed items
  Future<bool> removeAll() async {
    try {
      final result = await _channel.invokeMethod('removeAll');
      return result == true;
    } catch (_) {
      return false;
    }
  }
}
