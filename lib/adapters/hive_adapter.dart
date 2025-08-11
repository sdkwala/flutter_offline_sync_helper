import 'package:hive/hive.dart';
import '../core/local_adapter.dart';
import '../models/sync_status.dart';

class HiveAdapter<T> implements LocalAdapter<T> {
  final String boxName;
  final String Function(T)? keyGenerator;
  final Map<String, dynamic> Function(T)? serializer;
  final T Function(Map<String, dynamic>)? deserializer;
  final bool storeAsMap;

  HiveAdapter(
      this.boxName, {
        this.keyGenerator,
        this.serializer,
        this.deserializer,
        this.storeAsMap = false,
      });

  Future<Box> get _box async => await Hive.openBox(boxName);

  String _generateKey(T model) {
    try {
      final dynamic dynamicModel = model;
      final localKey = dynamicModel.localKey;
      if (localKey != null && localKey is String) {
        return localKey;
      }
    } catch (_) {
    }

    if (keyGenerator != null) {
      return keyGenerator!(model);
    }

    try {
      final dynamic dynamicModel = model;
      return dynamicModel.id?.toString() ??
          dynamicModel.key?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
    } catch (_) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Map<String, dynamic> _serializeModel(T model) {
    final now = DateTime.now().toIso8601String();

    if (serializer != null) {
      final map = Map<String, dynamic>.from(serializer!(model));
      map['_syncStatus'] = SyncStatus.pending.index;
      map['_lastSynced'] = null;
      map['_createdAt'] = now;
      map['_updatedAt'] = now;
      return map;
    }

    if (model is Map) {
      final map = Map<String, dynamic>.from(model);
      map['_syncStatus'] = SyncStatus.pending.index;
      map['_lastSynced'] = null;
      map['_createdAt'] = now;
      map['_updatedAt'] = now;
      return map;
    }

    try {
      final modelMap = model as dynamic;
      final map = <String, dynamic>{};

      final fields = ['id', 'name', 'title', 'description', 'timestamp', 'createdAt', 'updatedAt'];
      for (final field in fields) {
        try {
          final value = modelMap.toJson()[field];
          if (value != null) {
            map[field] = value;
          }
        } catch (e) {
          print("Error accessing field $field: $e");
        }
      }

      map['_syncStatus'] = SyncStatus.pending.index;
      map['_lastSynced'] = null;
      map['_createdAt'] = DateTime.now().toIso8601String();
      map['_updatedAt'] = DateTime.now().toIso8601String();

      return map;
    } catch (e) {
      return {
        'data': model.toString(),
        '_syncStatus': SyncStatus.pending.index,
        '_createdAt': DateTime.now().toIso8601String(),
        '_updatedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  T _deserializeModel(Map<String, dynamic> map) {
    if (deserializer != null) {
      return deserializer!(map);
    }
    return map as T;
  }

  @override
  Future<void> saveLocally(T model) async {
    final box = await _box;
    final key = _generateKey(model);
    final data = _serializeModel(model);
    data['id'] ??= _extractIdFromKey(key);
    data['_syncAction'] = SyncAction.create.index;
    await box.put(key, storeAsMap ? data : model);
  }

  @override
  Future<List<T>> getPendingChanges() async {
    final box = await _box;
    final pending = <T>[];

    for (final key in box.keys) {
      final data = box.get(key);

      Map<String, dynamic>? map;
      if (storeAsMap && data is Map) {
        map = Map<String, dynamic>.from(data);
      } else if (!storeAsMap && serializer != null) {
        map = serializer!(data);
      }

      if (map != null) {
        final status = SyncStatus.values[map['_syncStatus'] ?? 0];
        if (status == SyncStatus.pending) {
          final model = _deserializeModel(map);
          try {
            (model as dynamic)._syncAction = SyncAction.values[map['_syncAction'] ?? 0];
          } catch (_) {}
          pending.add(model);
        }
      }
    }

    return pending;
  }

  @override
  Future<void> markAsSynced(List<T> models) async {
    final box = await _box;

    for (final model in models) {
      final key = _generateKey(model);

      if (storeAsMap) {
        await box.delete(key);
      } else {
        await box.delete(key);
      }
    }
  }

  int? _extractIdFromKey(String key) {
    return int.tryParse(key);
  }

  @override
  Future<void> updateLocally(T model) async {
    final box = await _box;
    final key = _generateKey(model);
    final data = _serializeModel(model);
    data['id'] ??= _extractIdFromKey(key);
    data['_syncAction'] = SyncAction.update.index;
    await box.put(key, storeAsMap ? data : model);
  }

  Future<void> deleteLocally(T model) async {
    final box = await _box;
    final key = _generateKey(model);
    final data = _serializeModel(model);
    data['_syncAction'] = SyncAction.delete.index;
    await box.delete(key);
  }


  Future<void> markAsConflict(T model) async {
    final box = await _box;
    final key = _generateKey(model);

    if (storeAsMap) {
      final existing = box.get(key) as Map<String, dynamic>?;
      if (existing != null) {
        existing['_syncStatus'] = SyncStatus.conflict.index;
        existing['_updatedAt'] = DateTime.now().toIso8601String();
        await box.put(key, existing);
      }
    }
  }

  Future<void> markAsError(T model, String error) async {
    final box = await _box;
    final key = _generateKey(model);

    if (storeAsMap) {
      final existing = box.get(key) as Map<String, dynamic>?;
      if (existing != null) {
        existing['_syncStatus'] = SyncStatus.error.index;
        existing['_error'] = error;
        existing['_updatedAt'] = DateTime.now().toIso8601String();
        await box.put(key, existing);
      }
    }
  }
}