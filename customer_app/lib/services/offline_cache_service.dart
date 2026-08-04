import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/logger.dart';

final offlineCacheProvider = Provider((ref) => OfflineCacheService());

class OfflineCacheService {
  static const String _dashboardKey = "techbes_offline_dashboard";
  static const String _notificationsKey = "techbes_offline_notifications";
  static const String _amcKey = "techbes_offline_amc";

  Future<void> cacheDashboard(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dashboardKey, json.encode(data));
      appLogger.d("OfflineCache: Dashboard cached successfully");
    } catch (e) {
      appLogger.e("OfflineCache: Failed to cache dashboard: $e");
    }
  }

  Future<Map<String, dynamic>?> getCachedDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_dashboardKey);
      if (str != null) {
        return json.decode(str) as Map<String, dynamic>;
      }
    } catch (e) {
      appLogger.e("OfflineCache: Failed to read cached dashboard: $e");
    }
    return null;
  }

  Future<void> cacheNotifications(List<dynamic> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notificationsKey, json.encode(list));
      appLogger.d("OfflineCache: Notifications cached successfully");
    } catch (e) {
      appLogger.e("OfflineCache: Failed to cache notifications: $e");
    }
  }

  Future<List<dynamic>?> getCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_notificationsKey);
      if (str != null) {
        return json.decode(str) as List<dynamic>;
      }
    } catch (e) {
      appLogger.e("OfflineCache: Failed to read cached notifications: $e");
    }
    return null;
  }

  Future<void> cacheAmc(List<dynamic> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_amcKey, json.encode(list));
      appLogger.d("OfflineCache: AMC details cached successfully");
    } catch (e) {
      appLogger.e("OfflineCache: Failed to cache AMC: $e");
    }
  }

  Future<List<dynamic>?> getCachedAmc() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_amcKey);
      if (str != null) {
        return json.decode(str) as List<dynamic>;
      }
    } catch (e) {
      appLogger.e("OfflineCache: Failed to read cached AMC: $e");
    }
    return null;
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dashboardKey);
      await prefs.remove(_notificationsKey);
      await prefs.remove(_amcKey);
      appLogger.d("OfflineCache: Caches cleared.");
    } catch (e) {
      appLogger.e("OfflineCache: Failed to clear cache: $e");
    }
  }
}
