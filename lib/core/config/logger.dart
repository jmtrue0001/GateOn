import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

var logger = Logger(
  filter: DefaultFilter(), // Use the default LogFilter (-> only log in debug mode)
  printer: PrettyPrinter(), // Use the PrettyPrinter to format and print log
  output: ConsoleOutput(), // Use the default LogOutput (-> send everything to console)
);

class ConsoleOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    if ((event.level == Level.error || event.level == Level.debug) && kDebugMode) {
      for (var line in event.lines) {
        log(line);
      }
    }
  }
}

class DefaultFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}
