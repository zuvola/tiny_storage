import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:isoworker/isoworker.dart';

class StorageImpl {
  late final IsoWorker _worker;
  late final String _path;

  // Whether it is being processed or not.
  bool get inProgress => _worker.inProgress;

  /// Initialization.
  Future<Map<String, dynamic>> init(
      String name, String path, StorageImpl? union) async {
    if (union != null) {
      _worker = union._worker;
    } else {
      _worker = await IsoWorker.init(_workerMethod);
    }
    _path = '$path${Platform.pathSeparator}$name';
    return await _worker.exec({
      'command': 'init',
      'path': _path,
    });
  }

  /// Write data to a file
  Future<void> flush(dynamic data) async {
    return _worker.exec({'command': 'flush', 'path': _path, 'data': data});
  }

  /// Removes all entries from the storage.
  Future<void> clear() async {
    return _worker.exec({'command': 'clear', 'path': _path});
  }

  /// Destroying object.
  Future<void> dispose() async => _worker.dispose();

  static void _workerMethod(Stream<WorkerData> message) {
    final Map<String, File> files = {};
    message.listen((data) {
      final command = data.value['command'];
      final path = data.value['path'] as String;
      switch (command) {
        case 'init':
          final file = File(path);
          files[path] = file;
          if (!file.existsSync()) {
            file.create(recursive: true);
          } else {
            try {
              data.callback(json.decode(file.readAsStringSync()));
              return;
            } catch (_) {}
          }
          data.callback(<String, dynamic>{});
          break;
        case 'clear':
          final file = files[path];
          file?.exists().then((exists) {
            if (exists) {
              file.delete().then((_) => data.callback(null));
            } else {
              data.callback(null);
            }
          });
          break;
        case 'flush':
          final file = files[path];
          final jsonstr = json.encode(data.value['data']);
          if (file != null && !file.existsSync()) {
            file.create(recursive: true);
          }
          file?.writeAsString(jsonstr).then((_) {
            data.callback(null);
          });
          break;
        default:
          data.callback(null);
      }
    });
  }
}
