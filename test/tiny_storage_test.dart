import 'dart:async';

import 'package:test/test.dart';
import 'package:tiny_storage/tiny_storage.dart';

void main() {
  late TinyStorage storage;
  setUp(() async {
    storage = await TinyStorage.init('test.txt', path: './tmp');
  });
  tearDown(() async {
    await Future.delayed(Duration(milliseconds: 200));
    storage.dispose();
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
  });

  test('clear twice', () async {
    await storage.clear();
    await storage.clear();
    final val = storage.get('key_2');
    expect(val, isNull);
  });

  test('null', () async {
    storage.set('key_1', null);
    final val = storage.get('key_1');
    expect(val, isNull);
  });

  test('flush in busy', () async {
    storage.set('key_1', 'val_1');
    storage.set('key_2', 2);
    await Future.delayed(Duration.zero);
    storage.set('key_3', [1, 2, 3]);
    storage.set('key_4', true);
    final val = storage.get('key_4');
    expect(val, true);
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
}
