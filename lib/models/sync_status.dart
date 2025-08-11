enum SyncStatus {
  synced,
  pending,
  conflict,
  error,
}

enum SyncAction {
  create,
  update,
  delete,
}

class SyncResult {
  final bool success;
  final List<dynamic>? conflicts;
  final String? error;
  final int syncedCount;
  final int failedCount;

  SyncResult({
    required this.success, 
    this.conflicts, 
    this.error,
    this.syncedCount = 0,
    this.failedCount = 0,
  });
}

class SyncableModel {
  final String id;
  final SyncStatus status;
  final DateTime? lastSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  SyncableModel({
    required this.id,
    this.status = SyncStatus.pending,
    this.lastSynced,
    required this.createdAt,
    required this.updatedAt,
  });

  SyncableModel copyWith({
    String? id,
    SyncStatus? status,
    DateTime? lastSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyncableModel(
      id: id ?? this.id,
      status: status ?? this.status,
      lastSynced: lastSynced ?? this.lastSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 