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
