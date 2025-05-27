// ignore: library_annotations
@TestOn('vm')

import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:tiny_storage/src/worker/io_worker.dart';

void main() {
  final tmpDir = Directory('./tmp');
  late String filePath;
  late StorageWorker worker;

  setUp(() async {
    filePath = '${tmpDir.path}/test.json';
    worker = StorageWorker();
  });

  tearDown(() async {
    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
  });

  group('StorageWorker', () {
    test('open creates file if not exists and returns empty map', () async {
      final result =
          await worker.execute({'command': 'open', 'path': filePath});
      expect(result, isA<Map>());
      expect(File(filePath).existsSync(), true);
    });

    test('open returns parsed JSON if file exists', () async {
      final file = File(filePath);
      final data = {'foo': 'bar'};
      await file.create(recursive: true);
      await file.writeAsString(json.encode(data));
      final result =
          await worker.execute({'command': 'open', 'path': filePath});
      expect(result, data);
    });

    test('open returns empty map if file has invalid JSON', () async {
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsString('not json');
      final result =
          await worker.execute({'command': 'open', 'path': filePath});
      expect(result, isA<Map>());
      expect(result, isEmpty);
    });

    test('flush writes data to file and returns true', () async {
      await worker.execute({'command': 'open', 'path': filePath});
      final data = {'a': 1, 'b': 2};
      final result = await worker
          .execute({'command': 'flush', 'path': filePath, 'data': data});
      expect(result, true);
      final fileContent = json.decode(File(filePath).readAsStringSync());
      expect(fileContent, data);
    });

    test('flush creates file if not exists', () async {
      final data = {'x': 42};
      final result = await worker
          .execute({'command': 'flush', 'path': filePath, 'data': data});
      expect(result, false); // file not open yet
      await worker.execute({'command': 'open', 'path': filePath});
      final result2 = await worker
          .execute({'command': 'flush', 'path': filePath, 'data': data});
      expect(result2, true);
      expect(File(filePath).existsSync(), true);
    });

    test('close removes file from internal map', () async {
      await worker.execute({'command': 'open', 'path': filePath});
      expect(worker.files.containsKey(filePath), true);
      await worker.execute({'command': 'close', 'path': filePath});
      expect(worker.files.containsKey(filePath), false);
    });

    test('delete removes file from disk and map', () async {
      await worker.execute({'command': 'open', 'path': filePath});
      await worker.execute({
        'command': 'flush',
        'path': filePath,
        'data': {'k': 'v'}
      });
      expect(File(filePath).existsSync(), true);
      await worker.execute({'command': 'delete', 'path': filePath});
      expect(File(filePath).existsSync(), false);
      expect(worker.files.containsKey(filePath), false);
    });

    test('delete does not throw if file does not exist', () async {
      await worker.execute({'command': 'open', 'path': filePath});
      await worker.execute({'command': 'close', 'path': filePath});
      expect(
          () async =>
              await worker.execute({'command': 'delete', 'path': filePath}),
          returnsNormally);
    });

    test('integration: open, flush, close, open again', () async {
      await worker.execute({'command': 'open', 'path': filePath});
      final data = {'hello': 'world'};
      await worker
          .execute({'command': 'flush', 'path': filePath, 'data': data});
      await worker.execute({'command': 'close', 'path': filePath});
      final result =
          await worker.execute({'command': 'open', 'path': filePath});
      expect(result, data);
    });
  });
}
