import 'package:web/web.dart';

/// Indicates whether the worker is running in a web environment.
bool get isWeb => true;

Future<void> clearTestData(String path) async {
  window.localStorage.clear();
}

bool fileExists(String path, String fileName) {
  final key = '$path/$fileName';
  return window.localStorage.getItem(key)?.isNotEmpty ?? false;
}
