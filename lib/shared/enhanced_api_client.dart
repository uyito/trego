import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class EnhancedApiClient {
  static EnhancedApiClient? _instance;
  late Dio _dio;
  String? _authToken;
  bool _isOnline = true;
  
  static const String baseUrl = kDebugMode 
      ? 'https://unfaceted-spissatus-neely.ngrok-free.app/api'
      : 'https://api.trego.app';

  EnhancedApiClient._() {
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
    _initConnectivityMonitoring();
  }

  static EnhancedApiClient get instance {
    _instance ??= EnhancedApiClient._();
    return _instance!;
  }

  void _setupInterceptors() {
    // Request interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        
        // Add platform headers
        options.headers['X-Platform'] = Platform.operatingSystem;
        options.headers['X-App-Version'] = '1.0.0';
        
        if (kDebugMode) {
          debugPrint('🚀 REQUEST: ${options.method} ${options.path}');
          if (options.data != null) {
            debugPrint('📤 DATA: ${options.data}');
          }
        }
        
        handler.next(options);
      },
      
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
        }
        handler.next(response);
      },
      
      onError: (error, handler) async {
        if (kDebugMode) {
          debugPrint('❌ ERROR: ${error.message}');
          debugPrint('URL: ${error.requestOptions.path}');
        }

        // Handle specific error types
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          // Retry logic for timeout errors
          final retryResult = await _retryRequest(error.requestOptions);
          if (retryResult != null) {
            handler.resolve(retryResult);
            return;
          }
        }

        // Handle 401 Unauthorized - token expired
        if (error.response?.statusCode == 401) {
          await _handleTokenExpired();
        }

        // Handle network errors
        if (error.type == DioExceptionType.connectionError) {
          _isOnline = false;
          // Try to serve from cache if available
          final cachedResponse = await _getCachedResponse(error.requestOptions.path);
          if (cachedResponse != null) {
            handler.resolve(cachedResponse);
            return;
          }
        }

        handler.next(error);
      },
    ));

    // Cache interceptor for offline support
    _dio.interceptors.add(CacheInterceptor());
  }

  void _initConnectivityMonitoring() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _isOnline = !results.contains(ConnectivityResult.none);
      if (_isOnline) {
        _syncPendingRequests();
      }
    });
  }

  Future<Response?> _retryRequest(RequestOptions options, {int retryCount = 0}) async {
    if (retryCount >= 3) return null;
    
    try {
      await Future.delayed(Duration(milliseconds: 1000 * (retryCount + 1)));
      return await _dio.request(
        options.path,
        data: options.data,
        queryParameters: options.queryParameters,
        options: Options(
          method: options.method,
          headers: options.headers,
        ),
      );
    } catch (e) {
      return await _retryRequest(options, retryCount: retryCount + 1);
    }
  }

  Future<void> _handleTokenExpired() async {
    // Clear expired token
    _authToken = null;
    await clearAuthToken();
    
    // Notify app to redirect to login
    // This would typically be handled by a global state manager
  }

  Future<Response?> _getCachedResponse(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cache_$path');
      if (cachedData != null) {
        return Response(
          requestOptions: RequestOptions(path: path),
          data: cachedData,
          statusCode: 200,
        );
      }
    } catch (e) {
      debugPrint('Error getting cached response: $e');
    }
    return null;
  }

  Future<void> _syncPendingRequests() async {
    // Implement sync logic for pending requests when back online
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingRequests = prefs.getStringList('pending_requests') ?? [];
      
      for (final request in pendingRequests) {
        // Process each pending request
        // This would involve parsing the request and re-executing it
      }
      
      // Clear pending requests after sync
      await prefs.remove('pending_requests');
    } catch (e) {
      debugPrint('Error syncing pending requests: $e');
    }
  }

  // Enhanced methods with better error handling
  Future<ApiResponse<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      if (!_isOnline) {
        final cachedResponse = await _getCachedResponse(path);
        if (cachedResponse != null) {
          return ApiResponse.success(cachedResponse.data);
        }
        return ApiResponse.failure('No internet connection', ApiErrorType.network);
      }

      final response = await _dio.get(path, queryParameters: queryParameters);
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.failure('Unexpected error: $e', ApiErrorType.unknown);
    }
  }

  Future<ApiResponse<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      if (!_isOnline) {
        // Queue request for later if offline
        await _queueRequest('POST', path, data: data, queryParameters: queryParameters);
        return ApiResponse.failure('Request queued for when online', ApiErrorType.network);
      }

      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.failure('Unexpected error: $e', ApiErrorType.unknown);
    }
  }

  Future<ApiResponse<T>> put<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      if (!_isOnline) {
        await _queueRequest('PUT', path, data: data, queryParameters: queryParameters);
        return ApiResponse.failure('Request queued for when online', ApiErrorType.network);
      }

      final response = await _dio.put(path, data: data, queryParameters: queryParameters);
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.failure('Unexpected error: $e', ApiErrorType.unknown);
    }
  }

  Future<ApiResponse<T>> delete<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      if (!_isOnline) {
        await _queueRequest('DELETE', path, queryParameters: queryParameters);
        return ApiResponse.failure('Request queued for when online', ApiErrorType.network);
      }

      final response = await _dio.delete(path, queryParameters: queryParameters);
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.failure('Unexpected error: $e', ApiErrorType.unknown);
    }
  }

  ApiResponse<T> _handleDioError<T>(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiResponse.failure('Request timeout', ApiErrorType.timeout);
      
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final message = e.response?.data?['message'] ?? 'Server error';
        
        if (statusCode >= 400 && statusCode < 500) {
          return ApiResponse.failure(message, ApiErrorType.client);
        } else if (statusCode >= 500) {
          return ApiResponse.failure(message, ApiErrorType.server);
        }
        return ApiResponse.failure(message, ApiErrorType.unknown);
      
      case DioExceptionType.connectionError:
        return ApiResponse.failure('No internet connection', ApiErrorType.network);
      
      case DioExceptionType.cancel:
        return ApiResponse.failure('Request cancelled', ApiErrorType.cancelled);
      
      default:
        return ApiResponse.failure('Network error', ApiErrorType.unknown);
    }
  }

  Future<void> _queueRequest(String method, String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingRequests = prefs.getStringList('pending_requests') ?? [];
      
      final request = {
        'method': method,
        'path': path,
        'data': data,
        'queryParameters': queryParameters,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      pendingRequests.add(request.toString());
      await prefs.setStringList('pending_requests', pendingRequests);
    } catch (e) {
      debugPrint('Error queueing request: $e');
    }
  }

  // Auth token management
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Connectivity check
  Future<bool> checkConnectivity() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  bool get isOnline => _isOnline;
}

// Enhanced response wrapper
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final ApiErrorType? errorType;

  ApiResponse.success(this.data) : isSuccess = true, error = null, errorType = null;
  ApiResponse.failure(this.error, this.errorType) : isSuccess = false, data = null;
}

enum ApiErrorType {
  network,
  timeout,
  client,
  server,
  cancelled,
  unknown,
}

// Cache interceptor for offline support
class CacheInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Cache GET responses
    if (response.requestOptions.method == 'GET' && response.statusCode == 200) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cache_${response.requestOptions.path}', response.data.toString());
      } catch (e) {
        debugPrint('Error caching response: $e');
      }
    }
    handler.next(response);
  }
}