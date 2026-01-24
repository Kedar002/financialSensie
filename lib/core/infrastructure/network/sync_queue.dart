import 'dart:convert';
import '../logger.dart';

/// Operation types for sync
enum SyncOperation { create, update, delete }

/// A queued operation waiting to be synced
class SyncItem {
  final String id;
  final String entityType;
  final int entityId;
  final SyncOperation operation;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;

  SyncItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'operation': operation.name,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory SyncItem.fromJson(Map<String, dynamic> json) {
    return SyncItem(
      id: json['id'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as int,
      operation: SyncOperation.values.firstWhere((e) => e.name == json['operation']),
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }
}

/// Offline-first sync queue.
/// Queues operations for later sync when network is unavailable.
///
/// This is the foundation for future cloud sync functionality.
class SyncQueue {
  static final SyncQueue _instance = SyncQueue._internal();
  static SyncQueue get instance => _instance;

  SyncQueue._internal();

  final List<SyncItem> _queue = [];
  final int _maxRetries = 3;
  bool _isSyncing = false;

  /// Add an operation to the queue
  void enqueue({
    required String entityType,
    required int entityId,
    required SyncOperation operation,
    required Map<String, dynamic> data,
  }) {
    final item = SyncItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${entityType}_$entityId',
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      data: data,
      createdAt: DateTime.now(),
    );

    _queue.add(item);
    Logger.debug(
      'Enqueued sync: ${operation.name} $entityType #$entityId',
      tag: 'Sync',
    );
  }

  /// Get pending sync count
  int get pendingCount => _queue.length;

  /// Check if there are pending syncs
  bool get hasPending => _queue.isNotEmpty;

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  /// Get all pending items (for display/debugging)
  List<SyncItem> get pendingItems => List.unmodifiable(_queue);

  /// Process the sync queue
  /// Returns the number of successfully synced items
  Future<int> processQueue(Future<bool> Function(SyncItem item) syncHandler) async {
    if (_isSyncing) {
      Logger.warning('Sync already in progress', tag: 'Sync');
      return 0;
    }

    if (_queue.isEmpty) {
      Logger.debug('No items to sync', tag: 'Sync');
      return 0;
    }

    _isSyncing = true;
    Logger.info('Starting sync of ${_queue.length} items', tag: 'Sync');

    int successCount = 0;
    final failedItems = <SyncItem>[];

    while (_queue.isNotEmpty) {
      final item = _queue.removeAt(0);

      try {
        final success = await syncHandler(item);

        if (success) {
          successCount++;
          Logger.debug(
            'Synced: ${item.operation.name} ${item.entityType} #${item.entityId}',
            tag: 'Sync',
          );
        } else {
          item.retryCount++;
          if (item.retryCount < _maxRetries) {
            failedItems.add(item);
            Logger.warning(
              'Sync failed, will retry: ${item.entityType} #${item.entityId}',
              tag: 'Sync',
            );
          } else {
            Logger.error(
              'Sync failed permanently: ${item.entityType} #${item.entityId}',
              tag: 'Sync',
            );
          }
        }
      } catch (e, st) {
        Logger.error(
          'Sync error: ${item.entityType} #${item.entityId}',
          error: e,
          stackTrace: st,
          tag: 'Sync',
        );
        item.retryCount++;
        if (item.retryCount < _maxRetries) {
          failedItems.add(item);
        }
      }
    }

    // Re-add failed items to the queue
    _queue.addAll(failedItems);

    _isSyncing = false;
    Logger.info(
      'Sync complete: $successCount successful, ${failedItems.length} failed',
      tag: 'Sync',
    );

    return successCount;
  }

  /// Clear the queue
  void clear() {
    _queue.clear();
    Logger.info('Sync queue cleared', tag: 'Sync');
  }

  /// Export queue as JSON (for persistence)
  String exportToJson() {
    return jsonEncode(_queue.map((item) => item.toJson()).toList());
  }

  /// Import queue from JSON (for persistence)
  void importFromJson(String json) {
    try {
      final list = jsonDecode(json) as List;
      _queue.clear();
      _queue.addAll(list.map((item) => SyncItem.fromJson(item as Map<String, dynamic>)));
      Logger.info('Imported ${_queue.length} sync items', tag: 'Sync');
    } catch (e) {
      Logger.error('Failed to import sync queue', error: e, tag: 'Sync');
    }
  }
}
