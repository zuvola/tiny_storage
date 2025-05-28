# tiny_storage

[![pub package](https://img.shields.io/pub/v/tiny_storage.svg)](https://pub.dartlang.org/packages/tiny_storage)

**[English](https://github.com/zuvola/tiny_storage/blob/master/README.md), [日本語](https://github.com/zuvola/tiny_storage/blob/master/README_jp.md)**

`tiny_storage` is a simple key-value store based on JSON files.  
It is a very small library, making its internal behavior easy to understand.

> **⚠️ Notice for version 2.0:**  
> This release includes breaking changes.  
> The usage and API have changed significantly from previous versions.  
> Please be sure to check the latest documentation and usage examples.

## Features

- Simple key-value store
- Data is saved as JSON files
- Fast write operations
  - Parallel file I/O using `Isolate`
  - Multiple writes in the same event loop are batched into a single operation
- Write order is guaranteed
- Small codebase

## Getting Started

```dart
import 'package:tiny_storage/tiny_storage.dart';

void main() async {
  final storage = await TinyStorage.init('test.json', path: './tmp');
  storage.set('key_1', 'value_1');
  storage.set('key_2', 2);
  storage.set('key_3', [1, 2, 3]);
  final ret = storage.get<String>('key_1');
  print(ret);
  await storage.close(); // Use close() to dispose
}
```

## Usage

### Initialization

Initialize by specifying the file name to save.  
If the file exists, it will be loaded automatically.  
For Flutter, specify the save path using [path_provider](https://pub.dev/packages/path_provider) or similar.

```dart
final storage = await TinyStorage.init('test.json', path: './tmp');
```

#### deferredSave option

If you set `deferredSave` to `true`, saving will be delayed by 1 second after calling `set`, and multiple sets within a short period will be batched into a single write.  
The default is `false` (immediate save).

```dart
final storage = await TinyStorage.init(
  'test.json',
  path: './tmp',
  deferredSave: true,
);
```

#### errorCallback option

The `errorCallback` is a callback that only receives errors that occur during the **save process (flush)**.  
You will receive the error object and stack trace.  
Errors that occur during other operations, such as file deletion or closing, are **not** passed to this callback.

```dart
final storage = await TinyStorage.init(
  'test.json',
  errorCallback: (error, stack) {
    print('Storage error: $error');
  },
);
```

For errors in other operations (e.g. `delete()`), handle them individually using `try-catch`:

```dart
try {
  await storage.delete();
} catch (e, stack) {
  print('Delete error: $e');
}
```

### Storing and Retrieving Data

You can store and retrieve values using a string key.  
Values are kept in memory immediately, and writes are performed at the end of the event loop or batched if deferred saving is enabled.

```dart
storage.set('key_1', 'value_1');
final ret = storage.get<String>('key_1');
```

### Deleting Data

Remove data by specifying the key.

```dart
storage.remove('key_1');
```

### Delete All Data and File

To delete all data and the file, use `delete()`.

```dart
await storage.delete();
```

### Dispose

When you are done using the storage, release resources with `close()`.

```dart
await storage.close();
```

### Get All Keys

You can get all currently registered keys.

```dart
final keys = storage.keys();
print(keys); // List<String>
```

### Force Save

Normally, saving is automatic, but you can explicitly save by calling `flush()`.

```dart
storage.flush();
```

### Wait Until All Saves Complete

If you want to wait until all save operations are complete, use `waitUntilIdle()`.

```dart
await storage.waitUntilIdle();
```

## Using with tiny_locator

Since `tiny_storage` loads files during `init`,  
it is recommended to share the instance using [tiny_locator](https://pub.dartlang.org/packages/tiny_locator) or similar when using it across multiple classes.

```dart
Future<void> A() async {
  // Register
  final storage = await TinyStorage.init('test.json', path: './tmp');
  locator.add<TinyStorage>(() => storage);
}
void B() {
  // Retrieve
  final storage = locator.get<TinyStorage>();
  final ret = storage.get<String>('key_1');
  print(ret);
}
```
