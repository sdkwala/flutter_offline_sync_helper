import 'package:connectivity_plus/connectivity_plus.dart';

import 'core/sync_manager.dart';
import 'core/local_adapter.dart';
import 'core/remote_sync_service.dart';
import 'core/conflict_resolver.dart';
import 'models/sync_status.dart';
import 'utils/connectivity_watcher.dart';
import 'adapters/hive_adapter.dart';
import 'adapters/drift_adapter.dart';

class OfflineSyncHelperConfig {
  final int maxRetries;
  final Duration retryDelay;
  final Duration syncInterval;
  final int batchSize;
  final bool enableConnectivityWatcher;
  final bool autoSyncOnConnectivityChange;

  const OfflineSyncHelperConfig({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 5),
    this.syncInterval = const Duration(minutes: 5),
    this.batchSize = 20,
    this.enableConnectivityWatcher = true,
    this.autoSyncOnConnectivityChange = true,
  });
}

class OfflineSyncHelper<T> {
   late SyncManager _manager;
   late OfflineSyncHelperConfig _config;
   ConnectivityWatcher? _connectivityWatcher;
   bool _isInitialized = false;
   static final Map<Type, dynamic> _instances = {};

   static OfflineSyncHelper<T> instance<T>() {
     if (!_instances.containsKey(T)) {
       throw StateError("OfflineSyncHelper<$T> is not initialized. Call initialize<T>() first.");
     }
     return _instances[T] as OfflineSyncHelper<T>;
   }
   OfflineSyncHelper._internal();

   static Future<void> initialize<T>({
     required LocalAdapter localAdapter,
     required RemoteSyncService remoteSyncService,
     ConflictResolver? conflictResolver,
     OfflineSyncHelperConfig? config,
   }) async {
     final instance = OfflineSyncHelper<T>._internal();

     instance._config = config ?? const OfflineSyncHelperConfig();

     if (instance._config.enableConnectivityWatcher) {
       instance._connectivityWatcher = ConnectivityWatcher();
     }

     instance._manager = SyncManager(
       localAdapter: localAdapter,
       remoteSyncService: remoteSyncService,
       conflictResolver: conflictResolver ?? ClientWinsResolver(),
       connectivityWatcher: instance._connectivityWatcher,
       maxRetries: instance._config.maxRetries,
       retryDelay: instance._config.retryDelay,
     );

     instance._isInitialized = true;

     // Save instance in the map
     _instances[T] = instance;

     if (instance._config.autoSyncOnConnectivityChange &&
         instance._connectivityWatcher != null) {
       instance._connectivityWatcher!.onConnectivityChanged.listen((result) {
         if (result != ConnectivityResult.none) {
           OfflineSyncHelper.instance<T>().syncNow();
         }
       });
     }
   }


   Future<void> save({required dynamic model}) async {
    _checkInitialization();
    await _manager.localAdapter.saveLocally(model);
    if (_config.autoSyncOnConnectivityChange) {
      if (_connectivityWatcher != null) {
        final connectivity = await _connectivityWatcher!.checkConnectivity();
        if (connectivity != ConnectivityResult.none) {
          syncNow();
        }
      }
    }
  }

  Future<void> update({required dynamic model}) async {
    _checkInitialization();
    await _manager.localAdapter.updateLocally(model);
    if (_config.autoSyncOnConnectivityChange) {
      if (_connectivityWatcher != null) {
        final connectivity = await _connectivityWatcher!.checkConnectivity();
        if (connectivity != ConnectivityResult.none) {
          syncNow();
        }
      }
    }
  }

  Future<void> delete({required dynamic model}) async {
    _checkInitialization();
    await _manager.localAdapter.deleteLocally(model);
    if (_config.autoSyncOnConnectivityChange) {
      if (_connectivityWatcher != null) {
        final connectivity = await _connectivityWatcher!.checkConnectivity();
        if (connectivity != ConnectivityResult.none) {
          syncNow();
        }
      }
    }
  }

  Future<SyncResult> syncNow() async {
    _checkInitialization();
    return await _manager.syncNow();
  }

   Future<List<T>> getPendingChanges() async {
    _checkInitialization();
    return (await _manager.localAdapter.getPendingChanges()).cast<T>();
  }

   Future<void> markAsSynced(List<T> models) async {
    _checkInitialization();
    await _manager.localAdapter.markAsSynced(models);
  }

   Future<void> markAsConflict(T model) async {
    _checkInitialization();
    if (_manager.localAdapter is HiveAdapter) {
      await (_manager.localAdapter as HiveAdapter).markAsConflict(model);
    } else if (_manager.localAdapter is DriftAdapter) {
      await (_manager.localAdapter as DriftAdapter).markAsConflict(model);
    }
  }

   Future<void> markAsError(T model, String error) async {
    _checkInitialization();
    if (_manager.localAdapter is HiveAdapter) {
      await (_manager.localAdapter as HiveAdapter).markAsError(model, error);
    } else if (_manager.localAdapter is DriftAdapter) {
      await (_manager.localAdapter as DriftAdapter).markAsError(model, error);
    }
  }

   Future<SyncStatus> getSyncStatus(T model) async {
    _checkInitialization();
    // This would need to be implemented based on the specific adapter
    // For now, return a default status
    return SyncStatus.pending;
  }

   Future<bool> isOnline() async {
    if (_connectivityWatcher != null) {
      final connectivity = await _connectivityWatcher!.checkConnectivity();
      return connectivity != ConnectivityResult.none;
    }
    return true; // Assume online if no connectivity watcher
  }

   Future<void> clearPendingChanges() async {
    _checkInitialization();
    final pending = await getPendingChanges();
    for (final model in pending) {
      await markAsSynced([model]);
    }
  }

   void _checkInitialization() {
     if (!_isInitialized) {
       throw StateError(
           'OfflineSyncHelper must be initialized before use. Call initialize() first.');
     }
   }

  // Configuration getters
   OfflineSyncHelperConfig get config => _config;
   bool get isInitialized => _isInitialized;
   ConnectivityWatcher? get connectivityWatcher => _connectivityWatcher;
}
