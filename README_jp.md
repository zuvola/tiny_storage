# tiny_storage

[![pub package](https://img.shields.io/pub/v/tiny_storage.svg)](https://pub.dartlang.org/packages/tiny_storage)

**[English](https://github.com/zuvola/tiny_storage/blob/master/README.md), [日本語](https://github.com/zuvola/tiny_storage/blob/master/README_jp.md)**


`tiny_storage`はJSONファイルをベースとしたシンプルなKey-Valueストアです。
また、とても小さなライブラリなので誰でも動きの把握がしやすくなっています。


## Features

- Key-Valueストア
- JSONファイルでの出力
- 早い
  - `Isolate`を使用しファイルI/Oを並列処理
  - 同一イベントループ内では複数回書き込み処理が走らない


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

### 初期化

保存するファイル名を指定して初期化します。  
ファイルが存在する場合は読み込み処理が走ります。  
Flutterの場合は[path_provider](https://pub.dev/packages/path_provider)などを使用して保存先パスの指定も必要になります。

```dart
final storage = await TinyStorage.init('test.txt', path: './tmp');
```

### 登録・取得

StringをキーにObjectの登録・取得を行います。  
値は即座にメモリ上に保持され、イベントループの最後にディスクへ書き込まれます。

```dart
storage.set('key_1', 'value_1');
final ret = storage.get('key_1');
}
```

### クリア

全てのデータとファイルを破棄します。

```dart
storage.clear();
```

### 破棄

不必要になったら`dispose`で破棄するようにしてください。

```dart
storage.dispose();
```


## Note

Web版は未実装になっています。


## tiny_locator

`tiny_storage`は`init`の際にファイル読み込み処理が走るので複数のクラスなどで使用する場合は
[tiny_locator](https://pub.dartlang.org/packages/tiny_locator)などを利用しインスタンスを共有する事をお勧めします。

```dart
Future<void> A() async {
  // 登録
  final storage = await TinyStorage.init('test.txt', path: './tmp');
  locator.add<TinyStorage>(() => storage);
}
void B() {
  // 取得
  final storage = locator.get<TinyStorage>();
  final ret = storage.get('key_1');
  print(ret);
}
```
