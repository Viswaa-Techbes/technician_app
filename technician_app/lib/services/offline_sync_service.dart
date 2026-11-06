import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'connectivity_service.dart';

final offlineSyncProvider = ChangeNotifierProvider<OfflineSyncService>((ref) {
  final service = OfflineSyncService();
  service.init();

  // Listen to connectivity changes to auto-sync when back online
  ref.listen<ConnectivityStatus>(connectivityProvider, (previous, next) {
    if (next == ConnectivityStatus.isConnected) {
      final api = ref.read(apiServiceProvider);
      service.syncPendingActions(api);
    }
  });

  return service;
});

class OfflineSyncService extends ChangeNotifier {
  static const String _queueKey = 'techbes_offline_action_queue';
  List<Map<String, dynamic>> _queue = [];
  bool _isSyncing = false;

  List<Map<String, dynamic>> get queue => _queue;
  int get pendingCount => _queue.length;
  bool get isSyncing => _isSyncing;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _queue = List<Map<String, dynamic>>.from(decoded);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[OfflineSync] Failed to initialize queue: $e');
    }
  }

  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_queueKey, jsonEncode(_queue));
      notifyListeners();
    } catch (e) {
      debugPrint('[OfflineSync] Failed to persist queue: $e');
    }
  }

  String? _lastSyncMessage;
  String? get lastSyncMessage => _lastSyncMessage;

  Future<void> queueStatusUpdate(
    String jobId,
    String status, {
    List<String>? attachments,
    String? note,
  }) async {
    // Duplicate prevention: avoid queuing the exact same status for the same job
    final alreadyQueued = _queue.any(
      (action) => action['jobId'] == jobId && action['status'] == status,
    );
    if (alreadyQueued) {
      debugPrint('[OfflineSync] Skipping duplicate queued status update: $status for job $jobId');
      return;
    }

    final item = {
      'id': 'action_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'status_update',
      'jobId': jobId,
      'status': status,
      'attachments': attachments ?? [],
      'note': note ?? '',
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    };

    _queue.add(item);
    await _saveQueue();
    debugPrint('[OfflineSync] Queued offline action: $status for job $jobId');
  }

  bool hasPendingForJob(String jobId) {
    return _queue.any((action) => action['jobId'] == jobId);
  }

  Future<int> syncPendingActions(ApiService api) async {
    if (_isSyncing || _queue.isEmpty) return 0;
    _isSyncing = true;
    notifyListeners();

    int successCount = 0;
    final remaining = <Map<String, dynamic>>[];

    for (final action in _queue) {
      try {
        if (action['type'] == 'status_update') {
          final jobId = action['jobId'] as String;
          final status = action['status'] as String;
          final attachments = (action['attachments'] as List?)?.map((e) => e.toString()).toList();
          final note = action['note'] as String?;

          await api.updateJobStatus(jobId, status, attachments: attachments, note: note);
          successCount++;
          debugPrint('[OfflineSync] Successfully synced action for job $jobId to status $status');
        }
      } catch (e) {
        debugPrint('[OfflineSync] Failed to sync action: $e');
        final retries = (action['retryCount'] as int? ?? 0) + 1;
        action['retryCount'] = retries;
        
        // Retain for retry if under limit
        if (retries <= 5) {
          remaining.add(action);
        } else {
          debugPrint('[OfflineSync] Dropping permanently failed action after $retries attempts: ${action['id']}');
        }
      }
    }

    _queue = remaining;
    await _saveQueue();
    _isSyncing = false;
    _lastSyncMessage = successCount > 0 
        ? 'Synced $successCount offline update${successCount > 1 ? 's' : ''}' 
        : null;
    notifyListeners();

    return successCount;
  }

  Future<void> clearQueue() async {
    _queue.clear();
    await _saveQueue();
  }
}
