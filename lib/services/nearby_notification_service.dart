import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/jps_item.dart';
import 'jps_api_service.dart';

class NearbyNotificationService {
  static const _enabledKey = 'nearby_notification_enabled';
  static const _radiusKey = 'nearby_notification_radius';
  static const _lastNotifiedKey = 'nearby_last_notified_ids';

  final JpsApiService _api;
  final FlutterLocalNotificationsPlugin _notifications;
  StreamSubscription<Position>? _positionSub;
  Position? _lastSearchPosition;
  bool _isEnabled = false;
  String _radius = '5km';

  NearbyNotificationService({
    required JpsApiService api,
    FlutterLocalNotificationsPlugin? notifications,
  })  : _api = api,
        _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  bool get isEnabled => _isEnabled;
  String get radius => _radius;

  Future<void> initialize() async {
    // 通知プラグイン初期化
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // 設定を読み込み
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_enabledKey) ?? false;
    _radius = prefs.getString(_radiusKey) ?? '5km';

    if (_isEnabled) {
      await startMonitoring();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (enabled) {
      await startMonitoring();
    } else {
      stopMonitoring();
    }
  }

  Future<void> setRadius(String radius) async {
    _radius = radius;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_radiusKey, radius);
  }

  Future<bool> requestPermissions() async {
    // 位置情報の許可
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    // 通知の許可
    final granted = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return granted ?? true;
  }

  Future<void> startMonitoring() async {
    stopMonitoring();

    final hasPermission = await requestPermissions();
    if (!hasPermission) return;

    // 位置変化を監視（significantChanges: バッテリー節約）
    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.low,
      distanceFilter: 500, // 500m移動ごとに発火
    );

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_onPositionChanged);
  }

  void stopMonitoring() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  Future<void> _onPositionChanged(Position position) async {
    // 前回の検索位置から1km以上移動した場合のみ検索
    if (_lastSearchPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastSearchPosition!.latitude,
        _lastSearchPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      if (distance < 1000) return; // 1km未満は無視
    }

    _lastSearchPosition = position;

    try {
      final result = await _api.searchByLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        radius: _radius,
        size: 5,
      );

      if (result.items.isEmpty) return;

      // 既に通知済みのアイテムを除外
      final prefs = await SharedPreferences.getInstance();
      final notifiedJson = prefs.getString(_lastNotifiedKey) ?? '[]';
      final notifiedIds =
          (jsonDecode(notifiedJson) as List).cast<String>().toSet();

      final newItems =
          result.items.where((item) => !notifiedIds.contains(item.id)).toList();

      if (newItems.isEmpty) return;

      // 最初の新しいアイテムで通知
      final item = newItems.first;
      await _showNotification(item, result.totalHits);

      // 通知済みIDを更新（直近100件まで保持）
      notifiedIds.add(item.id);
      final recentIds = notifiedIds.toList();
      if (recentIds.length > 100) {
        recentIds.removeRange(0, recentIds.length - 100);
      }
      await prefs.setString(_lastNotifiedKey, jsonEncode(recentIds));
    } catch (_) {
      // ネットワークエラー等は静かに無視
    }
  }

  Future<void> _showNotification(JpsItem item, int totalHits) async {
    const androidDetails = AndroidNotificationDetails(
      'nearby_cultural',
      '周辺の文化資源',
      channelDescription: '近くの文化資源を発見したときに通知します',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final body = item.spatial != null
        ? '${item.title}（${item.spatial}）他 $totalHits 件'
        : '${item.title} 他 $totalHits 件';

    await _notifications.show(
      item.id.hashCode,
      '近くに文化資源があります',
      body,
      details,
      payload: item.id,
    );
  }

  void dispose() {
    stopMonitoring();
  }
}
