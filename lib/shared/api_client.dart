import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static ApiClient? _instance;
  late Dio _dio;
  String? _authToken;
  
  static const String baseUrl = kDebugMode 
      ? 'http://localhost:3000'
      : 'https://api.trego.app';

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  void _setupInterceptors() {
    // Request interceptor - Add auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        
        if (kDebugMode) {
          print('🚀 REQUEST: ${options.method} ${options.path}');
          if (options.data != null) {
            print('📤 DATA: ${options.data}');
          }
        }
        
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          print('❌ ERROR: ${error.response?.statusCode} ${error.requestOptions.path}');
          print('ERROR DATA: ${error.response?.data}');
        }

        // Handle token expiration
        if (error.response?.statusCode == 401) {
          await _handleTokenExpiration();
          
          // Retry the request with new token if available
          if (_authToken != null) {
            try {
              final retryRequest = await _dio.fetch(error.requestOptions.copyWith(
                headers: {...error.requestOptions.headers, 'Authorization': 'Bearer $_authToken'},
              ));
              return handler.resolve(retryRequest);
            } catch (retryError) {
              handler.next(error);
            }
          }
        }

        // Handle rate limiting
        if (error.response?.statusCode == 429) {
          final retryAfter = error.response?.headers.value('retry-after');
          if (retryAfter != null) {
            await Future.delayed(Duration(seconds: int.parse(retryAfter)));
            try {
              final retryRequest = await _dio.fetch(error.requestOptions);
              return handler.resolve(retryRequest);
            } catch (retryError) {
              handler.next(error);
            }
          }
        }

        handler.next(error);
      },
    ));
  }

  Future<void> _handleTokenExpiration() async {
    try {
      // Try to refresh Firebase token and sync with backend
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('firebase_refresh_token');
      
      if (refreshToken != null) {
        // This would be handled by the auth service
        // For now, just clear the token
        await clearAuthToken();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling token expiration: $e');
      }
      await clearAuthToken();
    }
  }

  // Authentication methods
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<void> loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  // HTTP Methods
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Upload file
  Future<Response<T>> uploadFile<T>(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(file.path),
        if (additionalData != null) ...additionalData,
      });

      return await _dio.post<T>(
        path,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Check connectivity
  Future<bool> checkConnectivity() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// Custom API Exception class
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