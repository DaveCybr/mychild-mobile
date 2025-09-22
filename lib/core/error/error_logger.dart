enum ParseErrorType {
  jsonDecoding,
  fieldMissing,
  fieldTypeMismatch,
  networkError,
  unknown,
}

/// Data class to hold error details
class ParseError {
  final ParseErrorType type;
  final String message;
  final String? field;
  final dynamic originalData;
  final DateTime timestamp;
  final String? stackTrace;

  ParseError({
    required this.type,
    required this.message,
    this.field,
    this.originalData,
    DateTime? timestamp,
    this.stackTrace,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'message': message,
      'field': field,
      'originalData': originalData,
      'timestamp': timestamp.toIso8601String(),
      'stackTrace': stackTrace,
    };
  }

  @override
  String toString() {
    return 'ParseError(type: $type, message: $message, field: $field)';
  }
}

/// Main error logger class that was missing from your code
class ParseErrorLogger {
  final List<ParseError> _errors = [];
  final int maxErrors;
  final bool enableLogging;

  ParseErrorLogger({
    this.maxErrors = 100,
    this.enableLogging = true,
  });

  /// Log a parsing error (Retrofit-compatible signature)
  void logError(Object error, StackTrace stackTrace, dynamic requestOptions) {
    if (!enableLogging) return;

    final parseError = ParseError(
      type: _determineErrorType(error),
      message: error.toString(),
      originalData: requestOptions,
      stackTrace: stackTrace.toString(),
    );

    _errors.add(parseError);

    // Keep only the most recent errors
    if (_errors.length > maxErrors) {
      _errors.removeAt(0);
    }

    // Print to console in debug mode
    if (enableLogging) {
      print('ParseError: $parseError');
    }
  }

  /// Helper method to determine error type from exception
  ParseErrorType _determineErrorType(Object error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('json') || errorString.contains('parse')) {
      return ParseErrorType.jsonDecoding;
    } else if (errorString.contains('field') || errorString.contains('null')) {
      return ParseErrorType.fieldMissing;
    } else if (errorString.contains('type') || errorString.contains('cast')) {
      return ParseErrorType.fieldTypeMismatch;
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return ParseErrorType.networkError;
    }
    
    return ParseErrorType.unknown;
  }

  /// Manual logging method for custom error reporting
  void logCustomError({
    required ParseErrorType type,
    required String message,
    String? field,
    dynamic originalData,
    String? stackTrace,
  }) {
    if (!enableLogging) return;

    final error = ParseError(
      type: type,
      message: message,
      field: field,
      originalData: originalData,
      stackTrace: stackTrace,
    );

    _errors.add(error);

    // Keep only the most recent errors
    if (_errors.length > maxErrors) {
      _errors.removeAt(0);
    }

    // Print to console in debug mode
    if (enableLogging) {
      print('ParseError: $error');
    }
  }

  /// Get all logged errors
  List<ParseError> get errors => List.unmodifiable(_errors);

  /// Get errors by type
  List<ParseError> getErrorsByType(ParseErrorType type) {
    return _errors.where((error) => error.type == type).toList();
  }

  /// Get recent errors (last n errors)
  List<ParseError> getRecentErrors(int count) {
    final startIndex = _errors.length > count ? _errors.length - count : 0;
    return _errors.sublist(startIndex);
  }

  /// Clear all errors
  void clearErrors() {
    _errors.clear();
  }

  /// Get error summary
  Map<ParseErrorType, int> getErrorSummary() {
    final summary = <ParseErrorType, int>{};
    for (final error in _errors) {
      summary[error.type] = (summary[error.type] ?? 0) + 1;
    }
    return summary;
  }

  /// Export errors as JSON
  List<Map<String, dynamic>> exportErrors() {
    return _errors.map((error) => error.toJson()).toList();
  }
}

/// Singleton instance for global access
class GlobalErrorLogger {
  static final ParseErrorLogger _instance = ParseErrorLogger();
  static ParseErrorLogger get instance => _instance;
}
