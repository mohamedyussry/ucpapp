import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class CacheService {
  static const String _boxName = 'app_cache';
  static Box? _box;

  // Initialize Hive box
  static Future<void> init() async {
    if (_box != null && _box!.isOpen) return;

    try {
      // Hive is already initialized in main.dart
      _box = await Hive.openBox(_boxName);
    } catch (e) {
      developer.log('Failed to open cache box: $e');
    }
  }

  // Save data to cache with expiration
  static Future<void> set(
    String key,
    dynamic data, {
    Duration expiration = const Duration(hours: 1),
  }) async {
    if (_box == null) await init();

    final cacheEntry = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiration': expiration.inMilliseconds,
    };

    await _box?.put(key, jsonEncode(cacheEntry));
  }

  // Get data from cache
  static Future<dynamic> get(String key) async {
    if (_box == null) await init();

    final String? jsonString = _box?.get(key);
    if (jsonString == null) return null;

    try {
      final Map<String, dynamic> cacheEntry = jsonDecode(jsonString);
      final int timestamp = cacheEntry['timestamp'];
      final int expiration = cacheEntry['expiration'];
      final int now = DateTime.now().millisecondsSinceEpoch;

      if (now - timestamp > expiration) {
        // Cache expired
        await _box?.delete(key);
        return null;
      }

      return cacheEntry['data'];
    } catch (e) {
      developer.log('Error decoding cache for key $key: $e');
      return null;
    }
  }

  // Clear specific key
  static Future<void> remove(String key) async {
    if (_box == null) await init();
    await _box?.delete(key);
  }

  // Clear all cache
  static Future<void> clearAll() async {
    if (_box == null) await init();
    await _box?.clear();
  }
}
