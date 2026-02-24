import 'dart:developer' as dev;

class LoggerUtils {
  static void d(String message) {
    dev.log('DEBUG: $message', name: 'APP');
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    dev.log(
      'ERROR: $message',
      name: 'APP',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void i(String message) {
    dev.log('INFO: $message', name: 'APP');
  }
}
