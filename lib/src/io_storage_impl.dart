import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:isoworker/isoworker.dart';
import 'storage_impl.dart';

StorageImpl platformCreateStorage() {
  return IOStorageImpl();
}

class IOStorageImpl implements StorageImpl {
  late final IsoWorker _worker;
  late final String _path;

  @override
  bool get inProgress => _worker.inProgress;

  @override
  Future<Map<String, dynamic>> init(
      String name, String path, StorageImpl? union) async {
    if (union != null) {
      if (union is! IOStorageImpl) {
        throw ArgumentError('union must be IOStorageImpl');
      }
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

  @override
  Future<void> flush(dynamic data) async {
    final res = await _worker
        .exec<bool>({'command': 'flush', 'path': _path, 'data': data});
    assert(res, 'file is not opened: $_path');
  }

  @override
  Future<void> clear() async {
    return _worker.exec({'command': 'clear', 'path': _path});
  }

  @override
  Future<void> close() async {
    return _worker.exec({'command': 'close', 'path': _path});
  }

  @override
  Future<void> dispose() async => _worker.dispose();

  static void _workerMethod(Stream<WorkerData> message) {
    final Map<String, File> files = {};
    message.listen((data) async {
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
        case 'close':
          files.remove(path);
          data.callback(null);
          break;
        case 'clear':
          final file = files[path];
          final exists = await file?.exists();
          if (exists ?? false) {
            await file!.delete();
          }
          files.remove(path);
          data.callback(null);
          break;
        case 'flush':
          final file = files[path];
          final jsonstr = json.encode(data.value['data']);
          if (file == null) {
            data.callback(false);
            return;
          }
          if (!file.existsSync()) {
            await file.create(recursive: true);
          }
          await file.writeAsString(jsonstr);
          data.callback(true);
          break;
        default:
          data.callback(null);
      }
    });
  }
}
