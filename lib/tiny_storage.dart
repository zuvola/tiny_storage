library tiny_storage;

import 'dart:async';

import 'src/html.dart' if (dart.library.io) 'src/io.dart';

/// A simple key-value store based on JSON file
class TinyStorage {
  late StorageImpl _concrete;
  final Map<String, dynamic> _data = {};
  late _FlushTask _flush;

  /// Whether it is being processed or not.
  bool get inProgress => _concrete.inProgress;

  TinyStorage._(void Function(Object)? errorCallback) {
    _concrete = StorageImpl();
    _flush = _FlushTask(
      _concrete.flush,
      _data,
      errorCallback,
    );
  }

  /// Initialization.
  /// Specify the file name to save.
  static Future<TinyStorage> init(
    String name, {
    String path = '.',
    TinyStorage? union,
    void Function(Object)? errorCallback,
  }) async {
    final instance = TinyStorage._(errorCallback);
    final ret = await instance._concrete.init(
      name,
      path,
      union?._concrete,
    );
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

  /// Close the file.
  Future<void> close() async {
    await _concrete.close();
    _data.clear();
  }

  /// The value for the given [key], or `null` if [key] is not in the storage.
  T get<T>(String key) => _data[key] as T;

  /// Associates the [key] with the given [value].
  void set(String key, dynamic value) {
    if (value is Map || value is List || _data[key] != value) {
      _data[key] = value;
      _flush.run();
    }
  }

  /// Removes [key] from the storage.
  void remove(String key) {
    _data.remove(key);
    _flush.run();
  }

  /// Wait until idle.
  Future<void> waitUntilIdle() {
    return Future.microtask(() async {
      if (inProgress) {
        await Future.delayed(Duration(milliseconds: 50));
        return waitUntilIdle();
      }
    });
  }
}

enum _TaskState { free, lock, busy, next }

class _FlushTask {
  final Object data;
  final Future<void> Function(Object) flushFunc;
  final void Function(Object)? errorCallback;
  _TaskState state = _TaskState.free;

  _FlushTask(
    this.flushFunc,
    this.data,
    this.errorCallback,
  );

  void run() {
    if (state == _TaskState.busy) {
      state = _TaskState.next;
    }
    if (state == _TaskState.free) {
      state = _TaskState.lock;
      scheduleMicrotask(() async {
        state = _TaskState.busy;
        try {
          await flushFunc(data);
        } catch (e) {
          errorCallback?.call(e);
        }
        final next = state == _TaskState.next;
        state = _TaskState.free;
        if (next) {
          run();
        }
      });
    }
  }
}
