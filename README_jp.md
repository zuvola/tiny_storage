# tiny_storage

[![pub package](https://img.shields.io/pub/v/tiny_storage.svg)](https://pub.dartlang.org/packages/tiny_storage)

**[English](https://github.com/zuvola/tiny_storage/blob/master/README.md), [日本語](https://github.com/zuvola/tiny_storage/blob/master/README_jp.md)**

`tiny_storage`はJSONファイルをベースとしたシンプルなKey-Valueストアです。  
非常に小さなライブラリで、内部の動作も把握しやすくなっています。

> **⚠️ バージョン2.0のお知らせ:**  
> このリリースでは破壊的な変更が含まれています。  
> 以前のバージョンから使い方やAPIが大きく変更されています。  
> 必ず最新のドキュメントと使用例をご確認ください。

## 特徴

- シンプルなKey-Valueストア
- データはJSONファイルとして保存
- 高速な書き込み
  - `Isolate`を利用した並列ファイルI/O
  - 同一イベントループ内で複数回書き込みが発生しても1回にまとめて処理
- 書き込み順序を保証
- 小規模なコードベース

## はじめかた

```dart
import 'package:tiny_storage/tiny_storage.dart';

void main() async {
  final storage = await TinyStorage.init('test.json', path: './tmp');
  storage.set('key_1', 'value_1');
  storage.set('key_2', 2);
  storage.set('key_3', [1, 2, 3]);
  final ret = storage.get<String>('key_1');
  print(ret);
  await storage.close(); // 破棄は close() で行います
}
```

## 使い方

### 初期化

保存するファイル名を指定して初期化します。  
ファイルが存在する場合は自動的に読み込みます。  
Flutterの場合は[path_provider](https://pub.dev/packages/path_provider)などで保存先パスを指定してください。

```dart
final storage = await TinyStorage.init('test.json', path: './tmp');
```

#### deferredSave オプション

`deferredSave`を`true`にすると、set時の保存が1秒遅延され、短時間に複数回setした場合でも1回の書き込みにまとめられます。  
デフォルトは`false`（即時保存）です。

```dart
final storage = await TinyStorage.init(
  'test.json',
  path: './tmp',
  deferredSave: true,
);
```

#### errorCallback オプション

`errorCallback`は**保存処理（flush）時に発生したエラーのみ**を受け取るためのコールバックです。  
エラー内容とスタックトレースが渡されます。  
ファイル削除やクローズ時など、その他の操作で発生するエラーはこのコールバックでは受け取れません。

```dart
final storage = await TinyStorage.init(
  'test.json',
  errorCallback: (error, stack) {
    print('Storage error: $error');
  },
);
```

その他の操作（例: `delete()` など）で発生するエラーは、`try-catch`で個別にハンドリングしてください。

```dart
try {
  await storage.delete();
} catch (e, stack) {
  print('Delete error: $e');
}
```

### データの登録・取得

Stringをキーに値を登録・取得できます。  
値は即座にメモリ上に保持され、書き込みはイベントループの最後または遅延保存設定によりバッチで行われます。

```dart
storage.set('key_1', 'value_1');
final ret = storage.get<String>('key_1');
```

### データの削除

キーを指定してデータを削除します。

```dart
storage.remove('key_1');
```

### 全データ削除・ファイル削除

全てのデータとファイルを削除したい場合は `delete()` を使います。

```dart
await storage.delete();
```

### 破棄

ストレージを使い終わったら `close()` でリソースを解放してください。

```dart
await storage.close();
```

### キー一覧の取得

現在登録されている全てのキーを取得できます。

```dart
final keys = storage.keys();
print(keys); // List<String>
```

### 保存の即時実行

通常は自動で保存されますが、明示的に保存したい場合は `flush()` を呼びます。

```dart
storage.flush();
```

### 保存完了まで待機

全ての保存処理が完了するまで待機したい場合は `waitUntilIdle()` を使います。

```dart
await storage.waitUntilIdle();
```

## tiny_locatorとの併用

`tiny_storage`は`init`時にファイル読み込みが発生するため、複数クラスで使う場合は  
[tiny_locator](https://pub.dartlang.org/packages/tiny_locator)などでインスタンスを共有することを推奨します。

```dart
Future<void> A() async {
  // 登録
  final storage = await TinyStorage.init('test.json', path: './tmp');
  locator.add<TinyStorage>(() => storage);
}
void B() {
  // 取得
  final storage = locator.get<TinyStorage>();
  final ret = storage.get<String>('key_1');
  print(ret);
}
```
