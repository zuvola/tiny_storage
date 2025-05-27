// ignore: library_annotations
@TestOn('browser')

import 'package:test/test.dart';
import 'package:web/web.dart';
import 'package:tiny_storage/src/worker/web_worker.dart';

void main() {
  group('StorageWorker (web)', () {
    late StorageWorker worker;
    const testKey = 'test_storage_key';

    setUp(() {
      worker = StorageWorker();
      window.localStorage.removeItem(testKey);
    });

    tearDown(() {
      window.localStorage.removeItem(testKey);
    });

    test('open returns empty map if nothing stored', () async {
      final result = await worker.execute({'command': 'open', 'path': testKey});
      expect(result, isA<Map<String, dynamic>>());
      expect(result, isEmpty);
    });

    test('flush stores data and open retrieves it', () async {
      final data = {'foo': 123, 'bar': 'baz'};
      await worker.execute({'command': 'flush', 'path': testKey, 'data': data});
      final result = await worker.execute({'command': 'open', 'path': testKey});
      expect(result, data);
    });

    test('delete removes data', () async {
      final data = {'foo': 1};
      await worker.execute({'command': 'flush', 'path': testKey, 'data': data});
      await worker.execute({'command': 'delete', 'path': testKey});
      final result = await worker.execute({'command': 'open', 'path': testKey});
      expect(result, isEmpty);
    });

    test('close is a no-op', () async {
      final result =
          await worker.execute({'command': 'close', 'path': testKey});
      expect(result, isNull);
    });

    test('throws on unknown command', () async {
      expect(
        () => worker.execute({'command': 'unknown', 'path': testKey}),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('open returns empty map if stored data is invalid JSON', () async {
      window.localStorage.setItem(testKey, 'not a json');
      final result = await worker.execute({'command': 'open', 'path': testKey});
      expect(result, isA<Map<String, dynamic>>());
      expect(result, isEmpty);
    });
  });
}
