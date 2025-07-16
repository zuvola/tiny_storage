library tiny_storage;

import 'dart:async';

import 'package:tiny_storage/src/logging.dart';

import 'src/storage.dart';
import 'src/worker/worker_factory.dart';

/// A simple key-value store that saves data as JSON files.
class TinyStorage {
  /// The underlying storage implementation.
  final Storage _storage;

  /// In-memory key-value data.
  final Map<String, dynamic> _data = {};

  /// Task handler for flushing data to storage.
  late _FlushTask _flush;

  /// If true, saving is deferred and batched; otherwise, data is saved immediately.
  final bool deferredSave;

  /// Timer for scheduling deferred flushes.
  Timer? _deferredTimer;

  /// Returns true if a storage operation is currently in progress.
  bool get inProgress => _storage.inProgress;

  /// Private constructor for TinyStorage.
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

  /// Initializes a new TinyStorage instance and loads data from the specified file.
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

  /// Deletes the storage file and clears all in-memory data.
  Future<void> delete() async {
    _deferredTimer?.cancel();
    _deferredTimer = null;
    await waitUntilIdle();
    await _storage.delete();
    _data.clear();
  }

  /// Closes the storage file and clears all in-memory data.
  Future<void> close() async {
    if (_deferredTimer != null) {
      flush();
    }
    await waitUntilIdle();
    await _storage.close();
    _data.clear();
  }

  /// Returns the value associated with [key], or null if the key does not exist.
  T get<T>(String key) => _data[key] as T;

  /// Sets the value for [key]. Triggers a flush immediately or after a delay, depending on [deferredSave].
  void set(String key, dynamic value) {
    // Only update if value is a Map, List, or different from the current value.
    if (value is Map || value is List || _data[key] != value) {
      _data[key] = value;
      if (!deferredSave) {
        // Save immediately if not deferred.
        flush();
      } else {
        // Cancel any existing deferred flush timer.
        _deferredTimer?.cancel();
        // Schedule a new flush after 1 second.
        _deferredTimer = Timer(const Duration(seconds: 1), () {
          flush();
          _deferredTimer = null;
        });
      }
    }
  }

  /// Returns a list of all keys currently stored.
  List<String> keys() => List.unmodifiable(_data.keys);

  /// Removes the entry for [key] and flushes the change to storage.
  void remove(String key) {
    _data.remove(key);
    flush();
  }

  /// Writes the current in-memory data to storage.
  /// Cancels any pending deferred flush.
  void flush() {
    Logging.d(this, 'flush');
    _deferredTimer?.cancel();
    _deferredTimer = null;
    _flush.run();
  }

  /// Waits until all storage operations are idle before continuing.
  Future<void> waitUntilIdle() async {
    return Future.microtask(() async {
      if (inProgress) {
        await Future.delayed(Duration(milliseconds: 50));
        return waitUntilIdle();
      }
    });
  }
}

/// Internal state for the flush task.
enum _TaskState { free, lock, busy, next }

/// Handles scheduling and executing flush operations to storage.
class _FlushTask {
  /// The data to be flushed.
  final Object data;

  /// The function that performs the actual flush.
  final Future<void> Function(Object) flushFunc;

  /// Optional callback for handling errors during flush.
  final void Function(Object, StackTrace?)? errorCallback;

  /// Current state of the flush task.
  _TaskState state = _TaskState.free;

  /// Creates a new flush task.
  _FlushTask(
    this.flushFunc,
    this.data,
    this.errorCallback,
  );

  /// Runs the flush operation, ensuring only one flush is active at a time.
  /// If a flush is already in progress, schedules another flush to run after the current one.
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
