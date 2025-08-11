import 'package:connectivity_plus/connectivity_plus.dart';

import 'local_adapter.dart';
import 'remote_sync_service.dart';
import 'conflict_resolver.dart';
import '../models/sync_status.dart';
import '../utils/connectivity_watcher.dart';

class SyncManager<T> {
  final LocalAdapter<T> localAdapter;
  final RemoteSyncService<T> remoteSyncService;
  final ConflictResolver<T> conflictResolver;
  final ConnectivityWatcher? connectivityWatcher;
  final int maxRetries;
  final Duration retryDelay;

  SyncManager({
    required this.localAdapter,
    required this.remoteSyncService,
    required this.conflictResolver,
    this.connectivityWatcher,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 5),
  });
  Future<SyncResult> syncNow() async {
    try {
      if (connectivityWatcher != null) {
        final connectivity = await connectivityWatcher!.checkConnectivity();
        if (connectivity == ConnectivityResult.none) {
          return SyncResult(
            success: false,
            error: 'No internet connection',
            failedCount: 0,
          );
        }
      }
      final pending = await localAdapter.getPendingChanges();
      if (pending.isEmpty) {
        return SyncResult(
          success: true,
          syncedCount: 0,
          failedCount: 0,
        );
      }
      List<SyncAction> actions = [];
      for (final model in pending) {
        if (model is Map && model.containsKey('_syncAction')) {
          actions.add(SyncAction.values[model['_syncAction'] ?? 0]);
        }
        else {
          actions.add(SyncAction.create);
        }
      }
      SyncResult result;
      int attempts = 0;
      do {
        attempts++;
       result = await remoteSyncService.sync(pending, actions: actions);
        if (result.success) {
          await localAdapter.markAsSynced(pending);
          return SyncResult(
            success: true,
            syncedCount: pending.length,
            failedCount: 0,
          );
        } else {
          if (attempts < maxRetries) {
            await Future.delayed(retryDelay);
          }
        }
      } while (attempts < maxRetries && !result.success);
      if (result.conflicts != null && result.conflicts!.isNotEmpty) {
        await _handleConflicts(result.conflicts!);
      }
      return SyncResult(
        success: false,
        error: result.error,
        syncedCount: 0,
        failedCount: pending.length,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        error: e.toString(),
        syncedCount: 0,
        failedCount: 0,
      );
    }
  }

  Future<void> _handleConflicts(List<dynamic> conflicts) async {
    for (final conflict in conflicts) {
      if (conflict is Map && conflict.containsKey('local') && conflict.containsKey('remote')) {
        final resolved = conflictResolver.resolve(
          conflict['local'] as T,
          conflict['remote'] as T,
        );
        await localAdapter.saveLocally(resolved);
        await localAdapter.updateLocally(resolved);
        await localAdapter.deleteLocally(resolved);
      }
    }
  }
} 