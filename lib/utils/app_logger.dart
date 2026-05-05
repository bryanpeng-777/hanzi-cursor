import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
  ),
  level: kReleaseMode ? Level.off : Level.trace,
);

class AppLogger {
  AppLogger._();

  static void v(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.t(message, error: error, stackTrace: stackTrace);

  static void d(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.d(message, error: error, stackTrace: stackTrace);

  static void i(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.i(message, error: error, stackTrace: stackTrace);

  static void w(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  static void e(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
