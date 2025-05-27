class Logging {
  static final bool _debug = false;

  static _log(Object target, String message, Object? error) {
    if (!_debug) return;
    String className;
    if (target is String) {
      className = target;
    } else if (target is Type) {
      className = target.toString();
    } else {
      className = target.runtimeType.toString();
    }
    message = message.replaceAll('\n', ' ');
    if (error != null) {
      message = '$message: $error';
    }
    print('$className: $message');
  }

  static d(Object target, String message) {
    _log(target, message, null);
  }

  static e(Object target, String message, Object? error) {
    _log(target, message, error);
  }
}
