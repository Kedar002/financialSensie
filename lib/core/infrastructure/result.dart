/// A Result type for handling success/failure without exceptions.
/// Enables functional error handling throughout the app.
///
/// Usage:
/// ```dart
/// Result<User> result = await userRepo.getUser(id);
/// result.when(
///   success: (user) => print('Got user: ${user.name}'),
///   failure: (error) => print('Error: ${error.message}'),
/// );
/// ```
sealed class Result<T> {
  const Result();

  /// Create a success result
  factory Result.success(T data) = Success<T>;

  /// Create a failure result
  factory Result.failure(AppError error) = Failure<T>;

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T>;

  /// Get data if success, null if failure
  T? get dataOrNull {
    final self = this;
    if (self is Success<T>) return self.data;
    return null;
  }

  /// Get error if failure, null if success
  AppError? get errorOrNull {
    final self = this;
    if (self is Failure<T>) return self.error;
    return null;
  }

  /// Pattern match on the result
  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  }) {
    final self = this;
    if (self is Success<T>) {
      return success(self.data);
    } else if (self is Failure<T>) {
      return failure(self.error);
    }
    throw StateError('Invalid Result state');
  }

  /// Map the success value
  Result<R> map<R>(R Function(T data) transform) {
    return when(
      success: (data) => Result.success(transform(data)),
      failure: (error) => Result.failure(error),
    );
  }

  /// FlatMap for chaining Results
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    return when(
      success: (data) => transform(data),
      failure: (error) => Result.failure(error),
    );
  }

  /// Get data or throw the error
  T getOrThrow() {
    return when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  /// Get data or return default value
  T getOrDefault(T defaultValue) {
    return when(
      success: (data) => data,
      failure: (_) => defaultValue,
    );
  }

  /// Get data or compute default value
  T getOrElse(T Function(AppError error) orElse) {
    return when(
      success: (data) => data,
      failure: (error) => orElse(error),
    );
  }
}

/// Success result containing data
final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T> && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// Failure result containing error
final class Failure<T> extends Result<T> {
  final AppError error;

  const Failure(this.error);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure<T> && other.error == error;
  }

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}

/// Application error types
enum ErrorType {
  database,
  network,
  validation,
  notFound,
  unauthorized,
  unknown,
}

/// Structured application error
class AppError implements Exception {
  final ErrorType type;
  final String message;
  final String? code;
  final Object? originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  const AppError({
    required this.type,
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
    this.context,
  });

  /// Create a database error
  factory AppError.database(String message, {Object? error, StackTrace? stackTrace}) {
    return AppError(
      type: ErrorType.database,
      message: message,
      code: 'DB_ERROR',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Create a network error
  factory AppError.network(String message, {Object? error, StackTrace? stackTrace}) {
    return AppError(
      type: ErrorType.network,
      message: message,
      code: 'NETWORK_ERROR',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Create a validation error
  factory AppError.validation(String message, {Map<String, dynamic>? context}) {
    return AppError(
      type: ErrorType.validation,
      message: message,
      code: 'VALIDATION_ERROR',
      context: context,
    );
  }

  /// Create a not found error
  factory AppError.notFound(String resource) {
    return AppError(
      type: ErrorType.notFound,
      message: '$resource not found',
      code: 'NOT_FOUND',
    );
  }

  /// Create an unknown error
  factory AppError.unknown(Object? error, StackTrace? stackTrace) {
    return AppError(
      type: ErrorType.unknown,
      message: error?.toString() ?? 'An unknown error occurred',
      code: 'UNKNOWN_ERROR',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() => 'AppError[$code]: $message';

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'code': code,
      'context': context,
    };
  }
}

/// Extension for running async operations and returning Result
extension ResultExtension<T> on Future<T> {
  /// Convert a Future to a Result, catching exceptions
  Future<Result<T>> toResult() async {
    try {
      final data = await this;
      return Result.success(data);
    } catch (e, st) {
      return Result.failure(AppError.unknown(e, st));
    }
  }
}
