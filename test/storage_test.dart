import 'package:isoworker/isoworker.dart';
import 'package:test/test.dart';

import 'package:tiny_storage/src/storage.dart';

class DummyWorker extends WorkerClass<Object?, Map<String, Object>> {
  @override
  Future<Object?> execute(Map<String, Object> message) async {
    switch (message['command']) {
      case 'open':
        return {'status': 'opened'};
      case 'flush':
        return true;
      case 'delete':
        return null;
      case 'close':
        return null;
      default:
        throw Exception('Unknown command');
    }
  }
}

void main() {
  group('Storage', () {
    late Storage storage;
    const testFileName = 'testfile.db';
    final testPath = './tmp';

    setUp(() async {
      storage = await Storage.create(DummyWorker());
    });

    tearDown(() async {
      await storage.close();
    });

    test('open should set _isOpen and _path', () async {
      final result = await storage.open(testFileName, testPath);
      expect(result['status'], 'opened');
      expect(storage.inProgress, false);
    });

    test('flush should throw if not open', () async {
      expect(() => storage.flush({'foo': 'bar'}), throwsException);
    });

    test('flush should succeed after open', () async {
      await storage.open(testFileName, testPath);
      await storage.flush({'foo': 'bar'});
    });

    test('delete should throw if not open', () async {
      expect(() => storage.delete(), throwsException);
    });

    test('delete should succeed after open', () async {
      await storage.open(testFileName, testPath);
      await storage.delete();
    });

    test('close should succeed after open', () async {
      await storage.open(testFileName, testPath);
      await storage.close();
    });

    test('open should throw if already open', () async {
      await storage.open(testFileName, testPath);
      expect(() => storage.open(testFileName, testPath), throwsException);
    });
  });
}
