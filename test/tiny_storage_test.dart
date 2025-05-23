import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tiny_storage/tiny_storage.dart';

final testFileName = 'test.txt';
final testFilePath = './tmp';

void main() {
  group('main', () {
    late TinyStorage storage;
    Object? error;
    setUp(() async {
      storage = await TinyStorage.init(
        testFileName,
        path: testFilePath,
        errorCallback: (err) {
          error = err;
          print(err);
        },
      );
    });
    tearDown(() async {
      error = null;
      await storage.dispose();
    });
    test('set and get', () async {
      storage.set('key_1', 'val_1');
      dynamic val = storage.get<String>('key_1');
      expect(val, 'val_1');
      storage.set('key_2', 2);
      val = storage.get<int>('key_2');
      expect(val, 2);
      storage.set('key_3', [1, 2, 3]);
      val = storage.get<List>('key_3');
      expect(val[2], 3);
    });
    test('persistent', () async {
      final val = storage.get('key_2');
      expect(val, 2);
    });

    test('clear', () async {
      await storage.clear();
      final val = storage.get('key_2');
      expect(val, isNull);
      final file = File(testFilePath + Platform.pathSeparator + testFileName);
      expect(file.existsSync(), false);
      await storage.waitUntilIdle();
      expect(error, isNull);
    });

    test('clear twice', () async {
      await storage.clear();
      await storage.clear();
      final val = storage.get('key_2');
      expect(val, isNull);
      await storage.waitUntilIdle();
      expect(error, isNull);
    });

    test('clear and set', () async {
      await storage.clear();
      storage.set('key_1', 'val_1');
      dynamic val = storage.get<String>('key_1');
      expect(val, 'val_1');
      await storage.waitUntilIdle();
      expect(error, isNotNull);
    });

    test('close', () async {
      await storage.close();
      final val = storage.get('key_1');
      expect(val, isNull);
      final file = File(testFilePath + Platform.pathSeparator + testFileName);
      expect(file.existsSync(), true);
    });

    test('close and set', () async {
      await storage.close();
      storage.set('key_1', 'val_1');
      await storage.waitUntilIdle();
      final file = File(testFilePath + Platform.pathSeparator + testFileName);
      expect(file.existsSync(), true);
      expect(error, isNotNull);
    });

    test('null', () async {
      storage.set('key_1', null);
      final val = storage.get('key_1');
      expect(val, isNull);
    });

    test('flush in busy', () async {
      expect(storage.inProgress, false);
      storage.set('key_1', null);
      storage.set('key_1', 'val_1');
      expect(storage.inProgress, false);
      storage.set('key_2', 2);
      await Future.delayed(Duration.zero);
      expect(storage.inProgress, true);
      storage.set('key_3', [1, 2, 3]);
      storage.set('key_4', true);
      final val = storage.get('key_4');
      expect(val, true);
      expect(storage.inProgress, true);
      await storage.waitUntilIdle();
      expect(storage.inProgress, false);
    });

    test('persistent2', () async {
      final val = storage.get('key_4');
      expect(val, true);
    });

    test('save order safety', () async {
      storage.set('key_1', 'val_1');
      storage.set('key_1', List.generate(1000000, (index) => 'A').join());
      await Future.delayed(Duration.zero);
      storage.set('key_1', 'val_3');
      final val = storage.get<String>('key_1');
      expect(val, 'val_3');
    });

    test('persistent3', () async {
      final val = storage.get<String>('key_1');
      expect(val, 'val_3');
    });

    test('Map', () async {
      var map = {'a': 1};
      storage.set('key_map', map);
      await Future.delayed(Duration.zero);
      Map val = storage.get<Map>('key_map');
      expect(val, {'a': 1});
      map['a'] = 2;
      storage.set('key_map', map);
      val = storage.get<Map>('key_map');
      expect(val, {'a': 2});
    });

    test('persistent4', () async {
      final val = storage.get<Map>('key_map');
      expect(val, {'a': 2});
    });

    test('union', () async {
      final storage2 =
          await TinyStorage.init('test2.txt', path: './tmp', union: storage);
      storage.set('key_1', 'val_1');
      dynamic val = storage.get<String>('key_1');
      expect(val, 'val_1');
      storage2.set('key_union', 2);
      val = storage2.get<int>('key_union');
      expect(val, 2);
      val = storage.get('key_union');
      expect(val, null);
      await Future.delayed(Duration.zero);
      await storage2.dispose();

      storage.set('key_1', 'val_2');
      await Future.delayed(Duration.zero);
      val = storage.get<String>('key_1');
      expect(val, 'val_2');
      expect(error, isNull);
    });
  });

  group('deferredSave', () {
    late TinyStorage storage;
    final deferredFileName = 'deferred.txt';

    setUp(() async {
      storage = await TinyStorage.init(
        deferredFileName,
        path: testFilePath,
        deferredSave: true,
        errorCallback: (err) {},
      );
    });

    tearDown(() async {
      await storage.dispose();
      final file =
          File(testFilePath + Platform.pathSeparator + deferredFileName);
      if (file.existsSync()) file.deleteSync();
    });

    test('does not flush immediately on set', () async {
      storage.set('d_key', 'd_val');
      await Future.delayed(Duration(milliseconds: 50));
      final file =
          File(testFilePath + Platform.pathSeparator + deferredFileName);
      expect(file.lengthSync(), 0);
    });

    test('flushes after 11 sets', () async {
      for (var i = 0; i < 11; i++) {
        storage.set('d_key', 'val_$i');
      }
      await storage.waitUntilIdle();
      final file =
          File(testFilePath + Platform.pathSeparator + deferredFileName);
      expect(file.lengthSync() > 0, true);

      final newStorage = await TinyStorage.init(
        deferredFileName,
        path: testFilePath,
        deferredSave: true,
      );
      expect(newStorage.get<String>('d_key'), 'val_10');
      await newStorage.dispose();
    });

    test('manual flush works', () async {
      storage.set('manual_key', 'manual_val');
      storage.flush();
      await storage.waitUntilIdle();
      final file =
          File(testFilePath + Platform.pathSeparator + deferredFileName);
      expect(file.lengthSync() > 0, true);

      final newStorage = await TinyStorage.init(
        deferredFileName,
        path: testFilePath,
        deferredSave: true,
      );
      expect(newStorage.get<String>('manual_key'), 'manual_val');
      await newStorage.dispose();
    });

    test('dispose triggers flush', () async {
      storage.set('dispose_key', 'dispose_val');
      await storage.dispose();
      final file =
          File(testFilePath + Platform.pathSeparator + deferredFileName);
      expect(file.lengthSync() > 0, true);

      final newStorage = await TinyStorage.init(
        deferredFileName,
        path: testFilePath,
        deferredSave: true,
      );
      expect(newStorage.get<String>('dispose_key'), 'dispose_val');
      await newStorage.dispose();
    });

    test('does not flush if set <= 10 times', () async {
      for (var i = 0; i < 10; i++) {
        storage.set('not_flushed_key', 'val_$i');
      }
      await Future.delayed(Duration(milliseconds: 50));
      final file =
          File(testFilePath + Platform.pathSeparator + deferredFileName);
      expect(file.lengthSync(), 0);
    });
  });
}
