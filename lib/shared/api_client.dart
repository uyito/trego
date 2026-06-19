import 'dart:io';
import 'package:dio/dio.dart';
import 'enhanced_api_client.dart';

class ApiClient {
  static ApiClient? _instance;
  late EnhancedApiClient _enhancedClient;

  ApiClient._() {
    _enhancedClient = EnhancedApiClient.instance;
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  // Authentication methods - delegate to enhanced client
  Future<void> setAuthToken(String token) async {
    await _enhancedClient.setAuthToken(token);
  }

  Future<void> clearAuthToken() async {
    await _enhancedClient.clearAuthToken();
  }

  Future<void> loadAuthToken() async {
    await _enhancedClient.loadAuthToken();
  }

  // HTTP Methods - convert enhanced responses to legacy Dio responses
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _enhancedClient.get<T>(path, queryParameters: queryParameters);
    if (response.isSuccess) {
      return Response<T>(
        data: response.data,
        statusCode: 200,
        requestOptions: RequestOptions(path: path),
      );
    } else {
      throw ApiException(
        message: response.error ?? 'Unknown error',
        statusCode: _getStatusCodeFromErrorType(response.errorType),
      );
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _enhancedClient.post<T>(path, data: data, queryParameters: queryParameters);
    if (response.isSuccess) {
      return Response<T>(
        data: response.data,
        statusCode: 200,
        requestOptions: RequestOptions(path: path),
      );
    } else {
      throw ApiException(
        message: response.error ?? 'Unknown error',
        statusCode: _getStatusCodeFromErrorType(response.errorType),
      );
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _enhancedClient.put<T>(path, data: data, queryParameters: queryParameters);
    if (response.isSuccess) {
      return Response<T>(
        data: response.data,
        statusCode: 200,
        requestOptions: RequestOptions(path: path),
      );
    } else {
      throw ApiException(
        message: response.error ?? 'Unknown error',
        statusCode: _getStatusCodeFromErrorType(response.errorType),
      );
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _enhancedClient.patch<T>(path, data: data, queryParameters: queryParameters);
    if (response.isSuccess) {
      return Response<T>(
        data: response.data,
        statusCode: 200,
        requestOptions: RequestOptions(path: path),
      );
    } else {
      throw ApiException(
        message: response.error ?? 'Unknown error',
        statusCode: _getStatusCodeFromErrorType(response.errorType),
      );
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _enhancedClient.delete<T>(path, queryParameters: queryParameters);
    if (response.isSuccess) {
      return Response<T>(
        data: response.data,
        statusCode: 200,
        requestOptions: RequestOptions(path: path),
      );
    } else {
      throw ApiException(
        message: response.error ?? 'Unknown error',
        statusCode: _getStatusCodeFromErrorType(response.errorType),
      );
    }
  }

  // Upload file
  Future<Response<T>> uploadFile<T>(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
  }) async {
    // For file uploads, we'll use a basic implementation
    // This could be enhanced later with the same pattern
    throw UnimplementedError('File upload not yet implemented in enhanced client');
  }

  // Check connectivity
  Future<bool> checkConnectivity() async {
    return await _enhancedClient.checkConnectivity();
  }

  // Check if online
  bool get isOnline => _enhancedClient.isOnline;

  // Helper method to convert error types to status codes
  int? _getStatusCodeFromErrorType(ApiErrorType? errorType) {
    switch (errorType) {
      case ApiErrorType.client:
        return 400;
      case ApiErrorType.server:
        return 500;
      case ApiErrorType.timeout:
        return 408;
      case ApiErrorType.network:
        return null;
      case ApiErrorType.cancelled:
        return null;
      case ApiErrorType.unknown:
      default:
        return null;
    }
  }
}

// Custom API Exception class - keeping for backward compatibility
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorType;
  final Map<String, dynamic>? details;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errorType,
    this.details,
  });

  factory ApiException.fromDioError(DioException error) {
    String message = 'An error occurred';
    int? statusCode = error.response?.statusCode;
    String? errorType;
    Map<String, dynamic>? details;

    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      message = data['message'] ?? message;
      errorType = data['type'];
      details = data['details'];
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please check your network settings.';
        break;
      case DioExceptionType.badResponse:
        switch (statusCode) {
          case 400:
            message = details != null ? 'Validation failed' : 'Bad request';
            break;
          case 401:
            message = 'Authentication required. Please log in again.';
            break;
          case 403:
            message = 'Access denied. You don\'t have permission for this action.';
            break;
          case 404:
            message = 'The requested resource was not found.';
            break;
          case 429:
            message = 'Too many requests. Please wait a moment and try again.';
            break;
          case 500:
            message = 'Server error. Please try again later.';
            break;
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        break;
      case DioExceptionType.unknown:
        message = 'An unexpected error occurred';
        break;
      default:
        break;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      errorType: errorType,
      details: details,
    );
  }

  @override
  String toString() => message;

  bool get isNetworkError =>
      statusCode == null || statusCode! >= 500 || message.contains('connection');

  bool get isAuthError => statusCode == 401 || statusCode == 403;

  bool get isRateLimitError => statusCode == 429;

  bool get isValidationError => statusCode == 400 && details != null;
}