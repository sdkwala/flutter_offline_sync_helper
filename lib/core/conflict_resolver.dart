abstract class ConflictResolver<T> {
  T resolve(T local, T remote);
}

class ClientWinsResolver<T> implements ConflictResolver<T> {
  @override
  T resolve(T local, T remote) => local;
}

class ServerWinsResolver<T> implements ConflictResolver<T> {
  @override
  T resolve(T local, T remote) => remote;
}

class TimestampResolver<T> implements ConflictResolver<T> {
  @override
  T resolve(T local, T remote) {
    // Assuming models have a timestamp field
    // This is a generic implementation - specific models should override
    if (local is Map && remote is Map) {
      final localTimestamp = local['timestamp'] ?? 0;
      final remoteTimestamp = remote['timestamp'] ?? 0;
      return localTimestamp >= remoteTimestamp ? local : remote;
    }
    
    // For objects with timestamp property
    try {
      final localTimestamp = (local as dynamic).timestamp ?? 0;
      final remoteTimestamp = (remote as dynamic).timestamp ?? 0;
      return localTimestamp >= remoteTimestamp ? local : remote;
    } catch (e) {
      // Fallback to client wins if timestamp comparison fails
      return local;
    }
  }
} 