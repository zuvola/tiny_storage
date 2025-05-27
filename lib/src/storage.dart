import 'package:isoworker/isoworker.dart';

import 'single_worker.dart';

/// Storage implementation for managing file operations using a worker.
class Storage {
  // Worker instance for handling file operations asynchronously.
  late SingleWorker _worker;
  // File path for the storage file.
  late final String _path;
  // Flag indicating whether the storage is open.
  bool _isOpen = false;

  // Private constructor.
  Storage._();

  /// Creates a new Storage instance with the given worker.
  static Future<Storage> create(WorkerClass worker) async {
    final instance = Storage._();
    // Initialize the worker.
    instance._worker =
        await SingleWorker.create(() => IsoWorker.create(worker));
    return instance;
  }

  /// Returns whether a file operation is currently in progress.
  bool get inProgress => _worker.inProgress;

  /// Opens the storage file with the given name and path.
  /// Throws an exception if the file is already open.
  Future<Map<String, dynamic>> open(String name, String path) async {
    final filePath = path = '$path/$name';
    if (_isOpen) {
      throw Exception('file is already opened: $filePath');
    }
    _path = filePath;
    // Execute the open command on the worker.
    final ret = await _worker.exec({
      'command': 'open',
      'path': _path,
    });
    _isOpen = true;
    return ret;
  }

  /// Writes data to the storage file.
  /// Throws an exception if the file is not open or the flush fails.
  Future<void> flush(dynamic data) async {
    if (!_isOpen) {
      throw Exception('file is not opened');
    }
    final res = await _worker.exec<Map<String, Object>, bool>(
        {'command': 'flush', 'path': _path, 'data': data});
    if (res != true) {
      throw Exception('flush failed: $_path');
    }
  }

  /// Removes all entries from the storage and deletes the file.
  /// Throws an exception if the file is not open.
  Future<void> delete() async {
    if (!_isOpen) {
      throw Exception('file is not opened');
    }
    _isOpen = false;
    // Execute the delete command and dispose the worker.
    await _worker.exec({'command': 'delete', 'path': _path});
    await _worker.dispose();
  }

  /// Closes the storage file and disposes the worker.
  Future<void> close() async {
    if (!_isOpen) return;
    _isOpen = false;
    // Execute the close command and dispose the worker.
    await _worker.exec({'command': 'close', 'path': _path});
    await _worker.dispose();
  }
}
