import 'dart:async';

import 'package:test/test.dart';

import 'package:tiny_storage/src/storage_impl.dart';
import 'package:tiny_storage/tiny_storage.dart';

class MockStorageImpl implements StorageImpl {
  final Map<String, dynamic> data = {};
  bool _inProgress = false;

  @override
  bool get inProgress => _inProgress;

  @override
  Future<Map<String, dynamic>> init(
      String name, String path, StorageImpl? union) async {
    return data;
  }

  @override
  Future<void> dispose() async {
    data.clear();
  }

  @override
  Future<void> flush(dynamic newData) async {
    _inProgress = true;
    // Simulate async operation
    await Future.delayed(Duration(milliseconds: 100));
    data.clear();
    if (newData is Map) {
      data.addAll(newData as Map<String, dynamic>);
    }
    _inProgress = false;
  }

  @override
  Future<void> clear() async {
    data.clear();
  }

  @override
  Future<void> close() async {
    data.clear();
  }
}

void main() {
  group('TinyStorage with Mock', () {
    late MockStorageImpl mockStorage;
    late TinyStorage storage;

    setUp(() async {
      mockStorage = MockStorageImpl();
      storage =
          await TinyStorage.init('test.json', path: '.', storage: mockStorage);
    });

    test('init with mock storage', () {
      expect(storage, isNotNull);
    });

    test('set and get value', () async {
      storage.set('key', 'value');
      await storage.waitUntilIdle();
      expect(storage.get<String>('key'), equals('value'));
      expect(mockStorage.data['key'], equals('value'));
    });

    test('remove value', () async {
      storage.set('key', 'value');
      await storage.waitUntilIdle();
      storage.remove('key');
      await storage.waitUntilIdle();
      expect(() => storage.get<String>('key'), throwsA(isA<TypeError>()));
      expect(mockStorage.data['key'], isNull);
    });

    test('clear all values', () async {
      storage.set('key1', 'value1');
      storage.set('key2', 'value2');
      await storage.waitUntilIdle();
      await storage.clear();
      expect(() => storage.get<String>('key1'), throwsA(isA<TypeError>()));
      expect(() => storage.get<String>('key2'), throwsA(isA<TypeError>()));
      expect(mockStorage.data.isEmpty, isTrue);
    });

    test('inProgress status', () async {
      expect(storage.inProgress, isFalse);
      storage.set('key', 'value');
      await Future.delayed(Duration.zero);
      expect(storage.inProgress, isTrue);
      await storage.waitUntilIdle();
      expect(storage.inProgress, isFalse);
    });
  });
}
