library tiny_storage;

import 'dart:async';
import 'src/storage_impl.dart';
import 'src/storage_factory.dart';

/// A simple key-value store based on JSON file
class TinyStorage {
  final StorageImpl _concrete;
  final Map<String, dynamic> _data = {};
  late _FlushTask _flush;

  /// Whether to save data immediately or not.
  /// Considering performance, it is actually executed when the save process is called a certain number of times.
  final bool deferredSave;
  int _deferredSaveCount = 0;

  /// Whether it is being processed or not.
  bool get inProgress => _concrete.inProgress;

  TinyStorage._(
    StorageImpl? storage,
    void Function(Object)? errorCallback,
    this.deferredSave,
  ) : _concrete = storage ?? createDefaultStorage() {
    _flush = _FlushTask(
      _concrete.flush,
      _data,
      errorCallback,
    );
  }

  /// Initialization.
  /// Specify the file name to save.
  /// Creates a new instance of TinyStorage with the given storage implementation.
  static Future<TinyStorage> init(
    String name, {
    String path = '.',
    TinyStorage? union,
    void Function(Object)? errorCallback,
    StorageImpl? storage,
    bool deferredSave = false,
  }) async {
    final instance = TinyStorage._(storage, errorCallback, deferredSave);
    final ret = await instance._concrete.init(
      name,
      path,
      union?._concrete,
    );
    instance._data.addAll(ret);
    return instance;
  }

  /// Destroying object.
  Future<void> dispose() async {
    if (deferredSave) {
      flush();
      await waitUntilIdle();
    }
    return _concrete.dispose();
  }

  /// Removes all entries from the storage.
  Future<void> clear() => _clearOrClose(_concrete.clear);

  /// Close the file.
  Future<void> close() => _clearOrClose(_concrete.close);

  Future<void> _clearOrClose(Future<void> Function() func) async {
    await func();
    _data.clear();
  }

  /// The value for the given [key], or `null` if [key] is not in the storage.
  T get<T>(String key) => _data[key] as T;

  /// Associates the [key] with the given [value].
  void set(String key, dynamic value) {
    if (value is Map || value is List || _data[key] != value) {
      _data[key] = value;
      if (!deferredSave || ++_deferredSaveCount > 10) {
        flush();
        _deferredSaveCount = 0;
      }
    }
  }

  /// Returns a list of all keys in the storage.
  List<String> keys() => List.unmodifiable(_data.keys);

  /// Removes [key] from the storage.
  void remove(String key) {
    _data.remove(key);
    flush();
  }

  /// Flushes the data to the storage.
  /// If [deferredSave] is false, this method is called automatically when [set] is called.
  void flush() => _flush.run();

  /// Wait until idle.
  Future<void> waitUntilIdle() async {
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
        if (next) run();
      });
    }
  }
}
