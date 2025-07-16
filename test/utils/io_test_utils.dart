import 'dart:io';

/// Indicates whether the worker is running in a web environment.
bool get isWeb => false;

Future<void> clearTestData(String path) async {
  final tmpDir = Directory(path);
  if (await tmpDir.exists()) {
    await tmpDir.delete(recursive: true);
  }
}

bool fileExists(String path, String fileName) {
  final file = File(path + Platform.pathSeparator + fileName);
  return file.existsSync();
}
