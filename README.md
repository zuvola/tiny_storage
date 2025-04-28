# tiny_storage

[![pub package](https://img.shields.io/pub/v/tiny_storage.svg)](https://pub.dartlang.org/packages/tiny_storage)

**[English](https://github.com/zuvola/tiny_storage/blob/master/README.md), [日本語](https://github.com/zuvola/tiny_storage/blob/master/README_jp.md)**


`tiny_storage` is a simple key-value store based on JSON files.
It is also a very small library, so it is easy for anyone to understand how it works.


## Features

- Key-Value Store
- Output as JSON file
- Fast
  - Parallel processing of file I/O using `Isolate`.
  - Multiple write operations are not executed in the same event loop.
- Guaranteed write order, even for large data.


## Getting started

```dart
import 'package:tiny_storage/tiny_storage.dart';

void main() async {
  final storage = await TinyStorage.init('test.txt', path: './tmp');
  storage.set('key_1', 'value_1');
  storage.set('key_2', 2);
  storage.set('key_3', [1, 2, 3]);
  final ret = storage.get('key_1');
  print(ret);
  await storage.dispose();
}
```


## Usage

### Initialize

Specify the file name to save and initialize.
If the file exists, the loading process will run.  
In the case of Flutter, it is also necessary to specify the destination path using [path_provider](https://pub.dev/packages/path_provider).

```dart
final storage = await TinyStorage.init('test.txt', path: './tmp');
```

If you do not want to increase the number of threads when opening multiple files, specify a TinyStorage object to be shared in `union`. It will work on the same thread.

```dart
final storage = await TinyStorage.init('test1.txt', path: './tmp');
final storage2 = await TinyStorage.init('test2.txt', path: './tmp', union: storage);
```

### Registration and Retrieval

Registers and retrieves an Object using String as a key.  
The value is immediately held in memory and written to disk before the next event loop.

```dart
storage.set('key_1', 'value_1');
final ret = storage.get('key_1');
```

### Clear

Discard all data and the file.

```dart
storage.clear();
```

### Dispose

Use `dispose` to destroy it when it is no longer needed.

```dart
storage.dispose();
```


## Testing

You can create a mock implementation using the `StorageImpl` interface for testing purposes.

```dart
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
  Future<void> flush(dynamic newData) async {
    _inProgress = true;
    if (newData is Map) {
      data.clear();
      data.addAll(newData as Map<String, dynamic>);
    }
    _inProgress = false;
  }

  // Implement other methods...
}

void main() {
  test('TinyStorage with mock', () async {
    final mockStorage = MockStorageImpl();
    final storage = await TinyStorage.init(
      'test.json',
      path: '.',
      storage: mockStorage, // Inject mock implementation
    );

    storage.set('key', 'value');
    await storage.waitUntilIdle();
    expect(storage.get<String>('key'), equals('value'));
    expect(mockStorage.data['key'], equals('value'));
  });
}
```

## Note

The web version has not been implemented yet.


## tiny_locator

Since `tiny_storage` runs the file reading process at the time of` init`,
When using it in multiple classes, it is recommended to share the instance using [tiny_locator](https://pub.dartlang.org/packages/tiny_locator) etc.


```dart
Future<void> A() async {
  // Registration
  final storage = await TinyStorage.init('test.txt', path: './tmp');
  locator.add<TinyStorage>(() => storage);
}
void B() {
  // Acquisition
  final storage = locator.get<TinyStorage>();
  final ret = storage.get('key_1');
  print(ret);
}
```
