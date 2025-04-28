import 'html_storage_impl.dart' if (dart.library.io) 'io_storage_impl.dart';
import 'storage_impl.dart';

StorageImpl createDefaultStorage() {
  return platformCreateStorage();
}
