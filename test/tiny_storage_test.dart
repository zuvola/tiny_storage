import 'dart:async';
import 'utils/io_test_utils.dart'
    if (dart.library.html) 'utils/web_test_utils.dart';

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
        errorCallback: (err, stack) {
          error = err;
        },
      );
    });
    tearDown(() async {
      error = null;
      await storage.close();
      clearTestData(testFilePath);
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
      storage.set('key_2', 100);
      await storage.waitUntilIdle();

      final storage2 = await TinyStorage.init(
        testFileName,
        path: testFilePath,
      );

      final val = storage2.get('key_2');
      expect(val, 100);
      await storage2.close();
    });

    test('delete', () async {
      storage.set('key_2', 10);
      await storage.waitUntilIdle();

      await storage.delete();

      expect(fileExists(testFilePath, testFileName), false);

      final storage2 = await TinyStorage.init(
        testFileName,
        path: testFilePath,
      );

      final val = storage2.get('key_2');
      expect(val, isNull);

      expect(error, isNull);
      await storage2.close();
    });

    test('delete twice', () async {
      storage.set('key_2', 10);
      await storage.waitUntilIdle();

      await storage.delete();
      expectLater(storage.delete(), throwsA(isA<Exception>()));
    });

    test('delete and set', () async {
      await storage.delete();
      storage.set('key_1', 'val_1');
      await Future.delayed(Duration(milliseconds: 100));
      expect(error, isNotNull);
    });

    test('close', () async {
      await storage.close();
      final val = storage.get('key_1');
      expect(val, isNull);
      expect(fileExists(testFilePath, testFileName), true);
    });

    test('close and set', () async {
      await storage.close();
      storage.set('key_1', 'val_1');
      await storage.waitUntilIdle();
      expect(fileExists(testFilePath, testFileName), true);
      await Future.delayed(Duration(milliseconds: 100));
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
      if (!isWeb) {
        expect(storage.inProgress, true);
      }
      storage.set('key_3', [1, 2, 3]);
      storage.set('key_4', true);
      final val = storage.get('key_4');
      expect(val, true);
      if (!isWeb) {
        expect(storage.inProgress, true);
      }
      await storage.waitUntilIdle();
      expect(storage.inProgress, false);
      await storage.waitUntilIdle();

      final storage2 = await TinyStorage.init(
        testFileName,
        path: testFilePath,
      );

      final val2 = storage2.get('key_4');
      expect(val2, true);
      await storage2.close();
    });

    test('save order safety', () async {
      storage.set('key_1', 'val_1');
      storage.set('key_1', List.generate(1000000, (index) => 'A').join());
      await Future.delayed(Duration.zero);
      storage.set('key_1', 'val_3');
      final val = storage.get<String>('key_1');
      expect(val, 'val_3');
      await storage.waitUntilIdle();

      final storage2 = await TinyStorage.init(
        testFileName,
        path: testFilePath,
      );
      final val2 = storage2.get('key_1');
      expect(val2, 'val_3');
      await storage2.close();
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
      await storage.waitUntilIdle();

      final storage2 = await TinyStorage.init(
        testFileName,
        path: testFilePath,
      );
      final val2 = storage.get<Map>('key_map');
      expect(val2, {'a': 2});
      await storage2.close();
    });
  });
  group('deferredSave', () {
    late TinyStorage deferredStorage;
    Object? error;

    setUp(() async {
      deferredStorage = await TinyStorage.init(
        testFileName,
        path: testFilePath,
        deferredSave: true,
        errorCallback: (err, stack) {
          print('error: $err');
          error = err;
        },
      );
    });

    tearDown(() async {
      error = null;
      await deferredStorage.close();
      clearTestData(testFilePath);
    });

    test('flush is called after 1 second of inactivity', () async {
      deferredStorage.set('key', 'value1');
      // Set again before 1 second to reset the timer
      await Future.delayed(const Duration(milliseconds: 500));
      deferredStorage.set('key', 'value2');
      // Wait less than 1 second, flush should not be called yet
      await Future.delayed(const Duration(milliseconds: 700));
      // Data should still be in memory, not flushed yet
      final storage2 = await TinyStorage.init(
        testFileName,
        path: testFilePath,
      );
      expect(storage2.get('key'), isNull);

      // Wait enough time for flush to happen
      await Future.delayed(const Duration(milliseconds: 400));
      final storage3 = await TinyStorage.init(
        testFileName,
        path: testFilePath,
      );
      expect(storage3.get('key'), 'value2');

      await storage2.close();
      await storage3.close();
    });

    test('flush is not called if set is called repeatedly within 1 second',
        () async {
      for (int i = 0; i < 5; i++) {
        deferredStorage.set('counter', i);
        await Future.delayed(const Duration(milliseconds: 300));
      }
      // Wait less than 1 second after last set
      await Future.delayed(const Duration(milliseconds: 600));
      final storage2 = await TinyStorage.init(
        testFileName,
        path: testFilePath,
      );
      expect(storage2.get('counter'), isNull);

      // Wait enough time for flush to happen
      await Future.delayed(const Duration(milliseconds: 200));
      final storage3 = await TinyStorage.init(
        testFileName,
        path: testFilePath,
      );
      expect(storage3.get('counter'), 4);

      await storage2.close();
      await storage3.close();
    });

    test('close', () async {
      deferredStorage.set('key_2', 10);
      await deferredStorage.close();
      await clearTestData(testFilePath);

      await Future.delayed(Duration(seconds: 1));

      expect(error, isNull);
    });
  });
}
