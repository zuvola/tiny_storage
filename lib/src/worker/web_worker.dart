import 'dart:async';
import 'dart:convert';
import 'package:web/web.dart';

import 'package:isoworker/isoworker.dart';

import '../logging.dart';

WorkerClass platformWorkerObject() => StorageWorker();

/// StorageWorker implementation for web using window.localStorage.
class StorageWorker extends WorkerClass<Object, Map<String, Object>> {
  @override
  Future<Object?> execute(data) async {
    final command = data['command'];
    final path = data['path'] as String;
    Logging.d(this, 'command: $command, path: $path');
    switch (command) {
      case 'open':
        final jsonStr = window.localStorage.getItem(path);
        final empty = <String, dynamic>{};
        if (jsonStr == null) {
          window.localStorage.setItem(path, json.encode(empty));
          return empty;
        }
        try {
          return json.decode(jsonStr);
        } catch (_) {
          return empty;
        }
      case 'flush':
        final map = data['data'];
        window.localStorage.setItem(path, json.encode(map));
        return true;
      case 'delete':
        window.localStorage.removeItem(path);
        return null;
      case 'close':
        // No-op for web/localStorage
        return null;
      default:
        throw UnsupportedError('Unknown command: $command');
    }
  }
}
