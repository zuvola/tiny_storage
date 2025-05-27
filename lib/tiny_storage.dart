library tiny_storage;

import 'dart:async';

import 'package:tiny_storage/src/logging.dart';

import 'src/storage.dart';
import 'src/worker/worker_factory.dart';

/// A simple key-value store based on JSON file
class TinyStorage {
  final Storage _storage;
  final Map<String, dynamic> _data = {};
  late _FlushTask _flush;

  /// Whether to save data immediately or not.
  final bool deferredSave;

  /// Timer for deferred flush
  Timer? _deferredTimer;

  /// Whether it is being processed or not.
  bool get inProgress => _storage.inProgress;

  TinyStorage._(
    this._storage,
    void Function(Object, StackTrace?)? errorCallback,
    this.deferredSave,
  ) {
    _flush = _FlushTask(
      _storage.flush,
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
    void Function(Object, StackTrace?)? errorCallback,
    bool deferredSave = false,
  }) async {
    final storage = await Storage.create(platformWorkerObject());
    final instance = TinyStorage._(storage, errorCallback, deferredSave);
    final ret = await instance._storage.open(name, path);
    instance._data.addAll(ret);
    return instance;
  }

  Future<void> delete() => _clearOrClose(_storage.delete);

  /// Close the file.
  Future<void> close() => _clearOrClose(_storage.close);

  Future<void> _clearOrClose(Future<void> Function() func) async {
    await waitUntilIdle();
    await func();
    _data.clear();
  }

  /// The value for the given [key], or `null` if [key] is not in the storage.
  T get<T>(String key) => _data[key] as T;

  /// Associates the [key] with the given [value].
  void set(String key, dynamic value) {
    if (value is Map || value is List || _data[key] != value) {
      _data[key] = value;
      if (!deferredSave) {
        flush();
      } else {
        // Cancel previous timer if running
        _deferredTimer?.cancel();
        // Start a new timer for 1 second
        _deferredTimer = Timer(const Duration(seconds: 1), () {
          flush();
          _deferredTimer = null;
        });
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
  void flush() {
    Logging.d(this, 'flush');
    _deferredTimer?.cancel();
    _deferredTimer = null;
    _flush.run();
  }

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
  final void Function(Object, StackTrace?)? errorCallback;
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
        } catch (e, s) {
          errorCallback?.call(e, s);
        }
        final next = state == _TaskState.next;
        state = _TaskState.free;
        if (next) run();
      });
    }
  }
}
