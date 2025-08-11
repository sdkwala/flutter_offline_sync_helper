import 'package:flutter_test/flutter_test.dart';
import 'package:offline_sync_helper/core/local_adapter.dart';
import 'package:offline_sync_helper/offline_sync_helper.dart';
import 'package:offline_sync_helper/core/remote_sync_service.dart';
import 'package:offline_sync_helper/core/conflict_resolver.dart';
import 'package:offline_sync_helper/models/sync_status.dart';

// Mock task model for testing
class TestTask {
  final String id;
  final String title;
  final DateTime timestamp;

  TestTask({
    required this.id,
    required this.title,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TestTask.fromJson(Map<String, dynamic> json) => TestTask(
    id: json['id'],
    title: json['title'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

// Mock local adapter for testing
class MockLocalAdapter<T> implements LocalAdapter<T> {
  final List<T> _pendingChanges = [];
  final List<T> _syncedItems = [];

  @override
  Future<void> saveLocally(T model) async {
    _pendingChanges.add(model);
  }

  @override
  Future<List<T>> getPendingChanges() async {
    return List.from(_pendingChanges);
  }

  @override
  Future<void> markAsSynced(List<T> models) async {
    for (final model in models) {
      _pendingChanges.remove(model);
      _syncedItems.add(model);
    }
  }

  List<T> get syncedItems => _syncedItems;
  List<T> get pendingChanges => _pendingChanges;

  @override
  Future<void> deleteLocally(T model) {
    // TODO: implement deleteLocally
    throw UnimplementedError();
  }

  @override
  Future<void> updateLocally(T model) {
    // TODO: implement updateLocally
    throw UnimplementedError();
  }
}

// Mock remote sync service for testing
class MockRemoteSyncService<T> implements RemoteSyncService<T> {
  bool shouldFail = false;
  String? errorMessage;
  List<dynamic>? conflicts;

  @override
  Future<SyncResult> sync(List<T> models, {List<SyncAction>? actions}) async {
    if (shouldFail) {
      return SyncResult(
        success: false,
        error: errorMessage ?? 'Mock sync failed',
        failedCount: models.length,
      );
    }

    if (conflicts != null && conflicts!.isNotEmpty) {
      return SyncResult(
        success: true,
        conflicts: conflicts,
        syncedCount: models.length,
      );
    }

    return SyncResult(
      success: true,
      syncedCount: models.length,
    );
  }
}

void main() {
  group('OfflineSyncHelper Tests', () {
    late MockLocalAdapter<TestTask> mockAdapter;
    late MockRemoteSyncService<TestTask> mockService;
    final syncHelper = OfflineSyncHelper.instance<TestTask>();


    setUp(() {
      mockAdapter = MockLocalAdapter<TestTask>();
      mockService = MockRemoteSyncService<TestTask>();
    });

    test('should initialize successfully', () async {
      await OfflineSyncHelper.initialize<TestTask>(
        localAdapter: mockAdapter,
        remoteSyncService: mockService,
      );

      // expect(OfflineSyncHelper<TestTask>.isInitialized, true);
    });

    test('should save model locally', () async {
      await OfflineSyncHelper.initialize<TestTask>(
        localAdapter: mockAdapter,
        remoteSyncService: mockService,
      );

      final task = TestTask(
        id: '1',
        title: 'Test Task',
        timestamp: DateTime.now(),
      );

      await OfflineSyncHelper.instance<TestTask>().save(model: task);

      expect(mockAdapter.pendingChanges.length, 1);
      expect(mockAdapter.pendingChanges.first, task);
    });

    test('should sync successfully', () async {
      await OfflineSyncHelper.initialize<TestTask>(
        localAdapter: mockAdapter,
        remoteSyncService: mockService,
      );

      final task = TestTask(
        id: '1',
        title: 'Test Task',
        timestamp: DateTime.now(),
      );

      await mockAdapter.saveLocally(task);

      final result = await OfflineSyncHelper.instance<TestTask>().syncNow();

      expect(result.success, true);
      expect(result.syncedCount, 1);
      expect(mockAdapter.pendingChanges.length, 0);
      expect(mockAdapter.syncedItems.length, 1);
    });

    test('should handle sync failure', () async {
      await OfflineSyncHelper.initialize<TestTask>(
        localAdapter: mockAdapter,
        remoteSyncService: mockService,
      );

      mockService.shouldFail = true;
      mockService.errorMessage = 'Network error';

      final task = TestTask(
        id: '1',
        title: 'Test Task',
        timestamp: DateTime.now(),
      );

      await mockAdapter.saveLocally(task);

      final result = await syncHelper.syncNow();

      expect(result.success, false);
      expect(result.error, 'Network error');
      expect(result.failedCount, 1);
      expect(mockAdapter.pendingChanges.length, 1); // Should still be pending
    });

    test('should handle conflicts', () async {
      await OfflineSyncHelper.initialize<TestTask>(
        localAdapter: mockAdapter,
        remoteSyncService: mockService,
        conflictResolver: ClientWinsResolver<TestTask>(),
      );

      mockService.conflicts = [
        {
          'local': TestTask(id: '1', title: 'Local', timestamp: DateTime.now()),
          'remote': TestTask(id: '1', title: 'Remote', timestamp: DateTime.now()),
        }
      ];

      final task = TestTask(
        id: '1',
        title: 'Test Task',
        timestamp: DateTime.now(),
      );

      await mockAdapter.saveLocally(task);

      final result = await syncHelper.syncNow();

      expect(result.success, true);
      expect(result.conflicts, isNotNull);
    });

    test('should get pending changes', () async {
      await OfflineSyncHelper.initialize<TestTask>(
        localAdapter: mockAdapter,
        remoteSyncService: mockService,
      );

      final task1 = TestTask(id: '1', title: 'Task 1', timestamp: DateTime.now());
      final task2 = TestTask(id: '2', title: 'Task 2', timestamp: DateTime.now());

      await mockAdapter.saveLocally(task1);
      await mockAdapter.saveLocally(task2);

      final pending = await syncHelper.getPendingChanges();

      expect(pending.length, 2);
      expect(pending.contains(task1), true);
      expect(pending.contains(task2), true);
    });

    test('should check online status', () async {
      await OfflineSyncHelper.initialize<TestTask>(
        localAdapter: mockAdapter,
        remoteSyncService: mockService,
        config: OfflineSyncHelperConfig(enableConnectivityWatcher: true),
      );

      final isOnline = await syncHelper.isOnline();

      // This will depend on the actual connectivity status
      expect(isOnline, isA<bool>());
    });

    test('should throw error when not initialized', () async {
      // Reset initialization state
      // Note: In a real implementation, you'd need a way to reset the static state

      expect(() async {
        await syncHelper.save(model: TestTask(
          id: '1',
          title: 'Test',
          timestamp: DateTime.now(),
        ));
      }, throwsStateError);
    });
  });

  group('Conflict Resolver Tests', () {
    test('ClientWinsResolver should return local', () {
      final resolver = ClientWinsResolver<TestTask>();
      final local = TestTask(id: '1', title: 'Local', timestamp: DateTime.now());
      final remote = TestTask(id: '1', title: 'Remote', timestamp: DateTime.now());

      final result = resolver.resolve(local, remote);

      expect(result, local);
    });

    test('ServerWinsResolver should return remote', () {
      final resolver = ServerWinsResolver<TestTask>();
      final local = TestTask(id: '1', title: 'Local', timestamp: DateTime.now());
      final remote = TestTask(id: '1', title: 'Remote', timestamp: DateTime.now());

      final result = resolver.resolve(local, remote);

      expect(result, remote);
    });

    test('TimestampResolver should return newer version', () {
      final resolver = TimestampResolver<TestTask>();
      final local = TestTask(id: '1', title: 'Local', timestamp: DateTime.now());
      final remote = TestTask(
        id: '1',
        title: 'Remote',
        timestamp: DateTime.now().add(Duration(hours: 1)),
      );

      final result = resolver.resolve(local, remote);

      expect(result, remote);
    });
  });

  group('SyncResult Tests', () {
    test('should create successful result', () {
      final result = SyncResult(
        success: true,
        syncedCount: 5,
        failedCount: 0,
      );

      expect(result.success, true);
      expect(result.syncedCount, 5);
      expect(result.failedCount, 0);
    });

    test('should create failed result', () {
      final result = SyncResult(
        success: false,
        error: 'Network error',
        syncedCount: 0,
        failedCount: 3,
      );

      expect(result.success, false);
      expect(result.error, 'Network error');
      expect(result.syncedCount, 0);
      expect(result.failedCount, 3);
    });
  });
}
