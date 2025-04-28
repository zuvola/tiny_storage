/// Interface for storage implementation
abstract class StorageImpl {
  /// Whether it is being processed or not.
  bool get inProgress;

  /// Initialization.
  Future<Map<String, dynamic>> init(
      String name, String path, StorageImpl? union);

  /// Destroying object.
  Future<void> dispose();

  /// Write data to a file
  Future<void> flush(dynamic data);

  /// Removes all entries from the storage.
  Future<void> clear();

  /// Close the file.
  Future<void> close();
}
