import 'package:isoworker/isoworker.dart';

import 'web_worker.dart' if (dart.library.io) 'io_worker.dart';

WorkerClass platformWorkerObject() => StorageWorker();
