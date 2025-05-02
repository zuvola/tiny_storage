## 1.4.1
- Fixed a bug in worker destruction when using union.

## 1.4.0
- Added `StorageImpl` interface for better testability and extensibility.
- Refactored storage implementations into separate classes (`IOStorageImpl` and `HTMLStorageImpl`).
- Added support for dependency injection through `storage` parameter in `TinyStorage.init`.
- Added example test cases using mock implementation.

## 1.3.0
- Added 'close' to close the current file.
- Added 'errorCallback' to get errors.

## 1.2.0
- Added 'inProgress' to indicate whether the process is in progress or not.
- Added 'waitUntilIdle' to wait until idle.

## 1.1.0
- Added 'union' to run on the same thread.

## 1.0.4
- Fixed data updates to Map and List.

## 1.0.3
- Avoided unnecessary saving when values are the same.

## 1.0.2
- Updated isoworker to fix a bug that sometimes files are not saved when exiting.

## 1.0.1
- Avoid error when clear is called multiple times

## 1.0.0+1
- Update README.

## 1.0.0
- Initial version.
