import 'storage_impl.dart';

StorageImpl platformCreateStorage() {
  return HTMLStorageImpl();
}

/// NotSupportedError
class NotSupportedError extends Error {
  final String message = 'not supported';
}

class HTMLStorageImpl implements StorageImpl {
  @override
  bool get inProgress => false;

  @override
  Future<Map<String, dynamic>> init(
      String name, String path, StorageImpl? union) async {
    throw NotSupportedError();
  }

  @override
  Future<void> dispose() async {
    throw NotSupportedError();
  }

  @override
  Future<void> flush(dynamic data) async {
    throw NotSupportedError();
  }

  @override
  Future<void> clear() async {
    throw NotSupportedError();
  }

  @override
  Future<void> close() async {
    throw NotSupportedError();
  }
}
