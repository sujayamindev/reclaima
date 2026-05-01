// coverage:ignore-file
import 'package:logger/logger.dart';

/// Global logger instance
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

/// Production logger (no colors, no emojis)
final productionLogger = Logger(
  printer: PrettyPrinter(methodCount: 0, colors: false, printEmojis: false),
);
