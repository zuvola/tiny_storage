import 'dart:async';
import 'package:isoworker/isoworker.dart';
import 'package:meta/meta.dart';

/// A singleton-like manager for a single [IsoWorker] instance.
///
/// This class uses reference counting to manage the lifecycle of a shared [IsoWorker].
/// Each call to [create] increases the reference count, and [dispose] decreases it.
/// When the reference count reaches zero, the worker is disposed.
class SingleWorker {
  /// Reference count for active SingleWorker instances.
  static int _refCount = 0;

  /// The shared IsoWorker instance.
  static IsoWorker? _worker;

  /// Indicates whether this SingleWorker instance has been disposed.
  bool _isDisposed = false;

  /// Private constructor to prevent direct instantiation.
  SingleWorker._();

  /// Creates (or reuses) a SingleWorker instance.
  ///
  /// The [factory] is called to create the IsoWorker if it doesn't exist yet.
  /// Increments the reference count.
  static Future<SingleWorker> create(
      Future<IsoWorker> Function() factory) async {
    final instance = SingleWorker._();
    _refCount++;
    _worker ??= await factory();
    return instance;
  }

  /// Returns true if the worker is currently processing a task.
  bool get inProgress => _worker?.inProgress ?? false;

  /// Executes a task on the worker with the given [data].
  ///
  /// Throws an exception if this instance has been disposed or if the worker is not initialized.
  Future<U> exec<T, U>(T data) async {
    if (_isDisposed) {
      throw Exception('Worker has been disposed');
    }
    if (_worker == null) {
      throw Exception('Worker is not initialized');
    }
    return await _worker!.exec<T, U>(data);
  }

  /// Disposes this SingleWorker instance.
  ///
  /// Decrements the reference count and disposes the worker if it reaches zero.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _refCount--;
    if (_refCount <= 0) {
      await _worker?.dispose();
      _worker = null;
      _refCount = 0;
    }
  }

  /// For testing: returns the current reference count.
  @visibleForTesting
  static int get refCount => _refCount;

  /// For testing: returns the current worker instance.
  @visibleForTesting
  static IsoWorker? get currentWorker => _worker;

  /// Resets static fields for testing purposes only.
  @visibleForTesting
  static void resetForTest() {
    _refCount = 0;
    _worker = null;
  }
}
