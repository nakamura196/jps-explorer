import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCacheService {
  static const _cacheDirName = 'image_cache';

  Future<String> getCacheDir() async {
    final docDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(docDir.path, _cacheDirName));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir.path;
  }

  String _fileNameForUrl(String url) {
    final hash = url.hashCode.toUnsigned(64).toRadixString(16);
    final ext = path.extension(Uri.parse(url).path);
    final suffix = ext.isNotEmpty ? ext : '.img';
    return '$hash$suffix';
  }

  Future<File?> getCachedImage(String url) async {
    final dir = await getCacheDir();
    final file = File(path.join(dir, _fileNameForUrl(url)));
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  Future<File> cacheImage(String url) async {
    final dir = await getCacheDir();
    final file = File(path.join(dir, _fileNameForUrl(url)));
    if (await file.exists()) {
      return file;
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
    } else {
      throw HttpException(
        'Failed to download image: ${response.statusCode}',
        uri: Uri.parse(url),
      );
    }
    return file;
  }

  Future<void> clearCache() async {
    final dir = Directory(await getCacheDir());
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<int> getCacheSize() async {
    final dir = Directory(await getCacheDir());
    if (!await dir.exists()) return 0;
    int totalSize = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }
}
