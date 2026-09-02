import "package:logger/logger.dart";

var logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 10000,
    colors: true,
    printEmojis: true,
  ),
);
