import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:isoworker/isoworker.dart';
import 'package:meta/meta.dart';

import '../logging.dart';

/// Returns a new instance of the platform-specific worker.
/// This function is used to abstract the worker creation.
WorkerClass platformWorkerObject() => StorageWorker();

/// StorageWorker handles file operations in an isolated worker context.
/// It supports opening, closing, deleting, and flushing (writing) files.
/// The worker communicates via commands and manages file handles internally.
class StorageWorker extends WorkerClass<Object, Map<String, Object>> {
  /// Internal map to keep track of open files by their path.
  final Map<String, File> _files = {};

  /// Exposes the internal file map for testing purposes.
  @visibleForTesting
  Map<String, File> get files => _files;

  /// Executes a command received by the worker.
  /// Supported commands:
  /// - 'open': Opens a file and reads its contents as JSON.
  /// - 'close': Removes the file handle from the internal map.
  /// - 'delete': Deletes the file from disk and removes its handle.
  /// - 'flush': Writes JSON data to the file.
  /// Returns the result of the operation or null if the command is unknown.
  @override
  Future<Object?> execute(data) async {
    final command = data['command'];
    final path = data['path'] as String;
    Logging.d(this, 'command: $command, path: $path');
    switch (command) {
      case 'open':
        final file = File(path);
        _files[path] = file;
        final exists = await file.exists();
        if (!exists) {
          // Create the file if it does not exist and return an empty map.
          await file.create(recursive: true);
          return <String, dynamic>{};
        } else {
          try {
            // Read and decode the file contents as JSON.
            final contents = await file.readAsString();
            return json.decode(contents);
          } catch (e) {
            Logging.e(this, 'Error reading file', e);
            return <String, dynamic>{};
          }
        }
      case 'close':
        // Remove the file handle from the internal map.
        _files.remove(path);
        break;
      case 'delete':
        final file = _files[path];
        try {
          final exists = await file?.exists();
          if (exists ?? false) {
            // Delete the file from disk if it exists.
            await file!.delete();
          }
        } catch (e) {
          Logging.e(this, 'Error deleting file', e);
          return false;
        }
        _files.remove(path);
        break;
      case 'flush':
        final file = _files[path];
        final jsonstr = json.encode(data['data']);
        if (file == null) {
          // File handle does not exist.
          return false;
        }
        try {
          final exists = await file.exists();
          if (!exists) {
            // Create the file if it does not exist.
            await file.create(recursive: true);
          }
          // Write the JSON string to the file.
          await file.writeAsString(jsonstr);
          return true;
        } catch (e) {
          Logging.e(this, 'Error writing file', e);
          return false;
        }
    }
    // Return null for unknown commands.
    return null;
  }
}
