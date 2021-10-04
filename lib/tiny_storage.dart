library tiny_storage;

import 'dart:async';

import 'src/html.dart' if (dart.library.io) 'src/io.dart';

/// A simple key-value store based on JSON file
class TinyStorage {
  late StorageImpl _concrete;
  final Map<String, dynamic> _data = {};
  late _FlushTask _flush;

  TinyStorage._() {
    _concrete = StorageImpl();
    _flush = _FlushTask(_concrete.flush);
  }

  /// Initialization.
  /// Specify the file name to save.
  static Future<TinyStorage> init(String name, {String path = '.'}) async {
    final instance = TinyStorage._();
    final ret = await instance._concrete.init(name, path);
    instance._data.addAll(ret);
    return instance;
  }

  /// Destroying object.
  Future<void> dispose() => _concrete.dispose();

  /// Removes all entries from the storage.
  Future<void> clear() async {
    await _concrete.clear();
    _data.clear();
  }

  /// The value for the given [key], or `null` if [key] is not in the storage.
  T get<T>(String key) => _data[key] as T;

  /// Associates the [key] with the given [value].
  void set(String key, dynamic value) {
    _data[key] = value;
    _flush.run(_data);
  }

  /// Removes [key] from the storage.
  void remove(String key) {
    _data.remove(key);
    _flush.run(_data);
  }
}

class _FlushTask {
  bool _rock = false;
  bool _busy = false;
  Object? _next;

  Function flushFunc;

  _FlushTask(this.flushFunc);

  void run(Object data) {
    if (_busy) {
      _next = data;
    }
    if (!_rock) {
      _rock = true;
      scheduleMicrotask(() async {
        _busy = true;
        await flushFunc(data);
        final next = _next;
        _rock = false;
        _next = null;
        _busy = false;
        if (next != null) {
          run(next);
        }
      });
    }
  }
}
