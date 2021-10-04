import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:isoworker/isoworker.dart';

class StorageImpl {
  late final IsoWorker _worker;

  /// Initialization.
  Future<Map<String, dynamic>> init(String name, String path) async {
    _worker = await IsoWorker.init(_workerMethod);
    return await _worker.exec({
      'command': 'init',
      'path': '$path${Platform.pathSeparator}$name',
    });
  }

  /// Write data to a file
  Future<void> flush(dynamic data) async {
    return _worker.exec({'command': 'flush', 'data': data});
  }

  /// Removes all entries from the storage.
  Future<void> clear() async {
    return _worker.exec({'command': 'clear'});
  }

  /// Destroying object.
  Future<void> dispose() async => _worker.dispose();

  static void _workerMethod(Stream<WorkerData> message) {
    late File _file;
    message.listen((data) {
      final command = data.value['command'];
      switch (command) {
        case 'init':
          final path = data.value['path'] as String;
          _file = File(path);
          if (!_file.existsSync()) {
            _file.create(recursive: true);
          } else {
            try {
              data.callback(json.decode(_file.readAsStringSync()));
              return;
            } catch (_) {}
          }
          data.callback(<String, dynamic>{});
          break;
        case 'clear':
          _file.delete().then((_) => data.callback(null));
          break;
        case 'flush':
          final jsonstr = json.encode(data.value['data']);
          if (!_file.existsSync()) {
            _file.create(recursive: true);
          }
          _file.writeAsString(jsonstr).then((_) {
            data.callback(null);
          });
          break;
        default:
          data.callback(null);
      }
    });
  }
}
