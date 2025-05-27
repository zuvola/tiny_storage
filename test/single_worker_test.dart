import 'dart:async';

import 'package:isoworker/isoworker.dart';
import 'package:test/test.dart';

import 'package:tiny_storage/src/single_worker.dart';

class MockIsoWorker implements IsoWorker {
  bool disposed = false;
  bool _inProgress = false;

  @override
  bool get inProgress => _inProgress;

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  Future<U> exec<T, U>(T data) async {
    _inProgress = true;
    await Future.delayed(Duration(milliseconds: 10));
    _inProgress = false;
    // Just echo the data back for testing
    return data as U;
  }
}

void main() {
  group('SingleWorker', () {
    setUp(() {
      // Reset static fields before each test using the provided method
      SingleWorker.resetForTest();
    });

    test('create initializes worker and increments ref count', () async {
      final worker = await SingleWorker.create(() async => MockIsoWorker());
      expect(worker, isA<SingleWorker>());
      expect(SingleWorker.refCount, 1);
      expect(SingleWorker.currentWorker, isNotNull);
    });

    test('multiple create calls share the same worker', () async {
      final worker1 = await SingleWorker.create(() async => MockIsoWorker());
      final worker2 = await SingleWorker.create(() async => MockIsoWorker());
      expect(SingleWorker.refCount, 2);
      expect(SingleWorker.currentWorker, isNotNull);
      expect(worker1 != worker2, true);
    });

    test('exec throws if disposed', () async {
      final worker = await SingleWorker.create(() async => MockIsoWorker());
      await worker.dispose();
      expect(() => worker.exec<String, String>('test'), throwsException);
    });

    test('exec returns result', () async {
      final worker = await SingleWorker.create(() async => MockIsoWorker());
      final result = await worker.exec<String, String>('hello');
      expect(result, 'hello');
    });

    test('dispose decrements ref count and disposes worker at zero', () async {
      final worker1 = await SingleWorker.create(() async => MockIsoWorker());
      final worker2 = await SingleWorker.create(() async => MockIsoWorker());
      await worker1.dispose();
      expect(SingleWorker.refCount, 1);
      expect(SingleWorker.currentWorker, isNotNull);
      await worker2.dispose();
      expect(SingleWorker.refCount, 0);
      expect(SingleWorker.currentWorker, isNull);
    });

    test('inProgress reflects worker state', () async {
      final worker = await SingleWorker.create(() async => MockIsoWorker());
      expect(worker.inProgress, false);
      final future = worker.exec<String, String>('test');
      expect(worker.inProgress, true);
      await future;
      expect(worker.inProgress, false);
    });
  });
}
