/// NotSupportedError
class NotSupportedError extends Error {
  final String message = 'not supported';
}

class StorageImpl {
  /// Initialization.
  Future<Map<String, dynamic>> init(String name, String path) async {
    throw NotSupportedError();
  }

  /// Destroying object.
  Future<void> dispose() async {
    throw NotSupportedError();
  }

  /// Write data to a file
  Future<void> flush(dynamic data) async {
    throw NotSupportedError();
  }

  /// Removes all entries from the storage.
  Future<void> clear() async {
    throw NotSupportedError();
  }
}
