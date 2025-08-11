abstract class LocalAdapter<T> {
  Future<void> saveLocally(T model);
  Future<List<T>> getPendingChanges();
  Future<void> markAsSynced(List<T> models);
  Future<void> updateLocally(T model);
  Future<void> deleteLocally(T model);
} 