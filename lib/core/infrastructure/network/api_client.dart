import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../logger.dart';
import '../result.dart';
import '../app_config.dart';

/// HTTP methods
enum HttpMethod { get, post, put, patch, delete }

/// API Client for making HTTP requests.
/// Ready for future backend integration.
///
/// Usage:
/// ```dart
/// final client = ApiClient();
/// final result = await client.get('/users/1');
/// result.when(
///   success: (data) => print(data),
///   failure: (error) => print(error.message),
/// );
/// ```
class ApiClient {
  final http.Client _httpClient;
  final String? _baseUrl;
  final Duration _timeout;
  final Map<String, String> _defaultHeaders;

  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    Duration? timeout,
    Map<String, String>? defaultHeaders,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.instance.settings.apiBaseUrl,
        _timeout = timeout ?? Duration(seconds: AppConfig.instance.settings.apiTimeoutSeconds),
        _defaultHeaders = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?defaultHeaders,
        };

  /// Set authorization token
  void setAuthToken(String token) {
    _defaultHeaders['Authorization'] = 'Bearer $token';
  }

  /// Remove authorization token
  void clearAuthToken() {
    _defaultHeaders.remove('Authorization');
  }

  /// Make a GET request
  Future<Result<Map<String, dynamic>>> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    return _request(
      method: HttpMethod.get,
      path: path,
      queryParams: queryParams,
      headers: headers,
    );
  }

  /// Make a POST request
  Future<Result<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return _request(
      method: HttpMethod.post,
      path: path,
      body: body,
      headers: headers,
    );
  }

  /// Make a PUT request
  Future<Result<Map<String, dynamic>>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return _request(
      method: HttpMethod.put,
      path: path,
      body: body,
      headers: headers,
    );
  }

  /// Make a PATCH request
  Future<Result<Map<String, dynamic>>> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return _request(
      method: HttpMethod.patch,
      path: path,
      body: body,
      headers: headers,
    );
  }

  /// Make a DELETE request
  Future<Result<Map<String, dynamic>>> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    return _request(
      method: HttpMethod.delete,
      path: path,
      headers: headers,
    );
  }

  /// Internal request method
  Future<Result<Map<String, dynamic>>> _request({
    required HttpMethod method,
    required String path,
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    if (_baseUrl == null) {
      return Result.failure(AppError.network(
        'API not configured. Running in offline mode.',
      ));
    }

    final uri = _buildUri(path, queryParams);
    final allHeaders = {..._defaultHeaders, ...?headers};

    Logger.debug(
      '${method.name.toUpperCase()} $uri',
      tag: 'API',
      data: body,
    );

    try {
      final response = await _executeRequest(method, uri, allHeaders, body)
          .timeout(_timeout);

      return _handleResponse(response);
    } on TimeoutException {
      Logger.error('Request timeout: $uri', tag: 'API');
      return Result.failure(AppError.network('Request timed out'));
    } catch (e, st) {
      Logger.error('Request failed: $uri', error: e, stackTrace: st, tag: 'API');
      return Result.failure(AppError.network('Network error: $e', error: e, stackTrace: st));
    }
  }

  Uri _buildUri(String path, Map<String, String>? queryParams) {
    final baseUri = Uri.parse(_baseUrl!);
    return baseUri.replace(
      path: '${baseUri.path}$path',
      queryParameters: queryParams,
    );
  }

  Future<http.Response> _executeRequest(
    HttpMethod method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) {
    final encodedBody = body != null ? jsonEncode(body) : null;

    switch (method) {
      case HttpMethod.get:
        return _httpClient.get(uri, headers: headers);
      case HttpMethod.post:
        return _httpClient.post(uri, headers: headers, body: encodedBody);
      case HttpMethod.put:
        return _httpClient.put(uri, headers: headers, body: encodedBody);
      case HttpMethod.patch:
        return _httpClient.patch(uri, headers: headers, body: encodedBody);
      case HttpMethod.delete:
        return _httpClient.delete(uri, headers: headers);
    }
  }

  Result<Map<String, dynamic>> _handleResponse(http.Response response) {
    Logger.debug(
      'Response ${response.statusCode}',
      tag: 'API',
      data: {'body': response.body.substring(0, response.body.length.clamp(0, 200))},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return Result.success({});
      }
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Result.success(data);
      } catch (e) {
        return Result.failure(AppError.network('Invalid JSON response'));
      }
    }

    // Handle error responses
    String message;
    try {
      final errorData = jsonDecode(response.body);
      message = errorData['message'] ?? errorData['error'] ?? 'Request failed';
    } catch (_) {
      message = 'Request failed with status ${response.statusCode}';
    }

    if (response.statusCode == 401) {
      return Result.failure(AppError(
        type: ErrorType.unauthorized,
        message: message,
        code: 'UNAUTHORIZED',
      ));
    }

    if (response.statusCode == 404) {
      return Result.failure(AppError.notFound('Resource'));
    }

    return Result.failure(AppError.network(message));
  }

  /// Close the client
  void dispose() {
    _httpClient.close();
  }
}
