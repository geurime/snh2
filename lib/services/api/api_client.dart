import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_exceptions.dart';

/// API 클라이언트 (싱글톤)
///
/// Dio 설정, 인터셉터, 인증 토큰 관리를 담당
class ApiClient {
  static const String baseUrl = 'https://snh2-production.up.railway.app/api';

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final Dio _dio;
  String? _accessToken;

  ApiClient._internal() : _dio = Dio(_createOptions()) {
    _dio.interceptors.add(_createLogInterceptor());
  }

  static BaseOptions _createOptions() {
    return BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  static Interceptor _createLogInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        if (kDebugMode) {
          print('[API] ${error.requestOptions.method} ${error.requestOptions.path} - Error: ${error.message}');
        }
        handler.next(error);
      },
    );
  }

  /// 인증 토큰 설정
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// 현재 토큰 존재 여부
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  /// 인증 헤더 옵션 생성
  Options _authOptions([Options? options]) {
    final mergedOptions = options ?? Options();
    if (_accessToken != null) {
      mergedOptions.headers = {
        ...?mergedOptions.headers,
        'Authorization': 'Bearer $_accessToken',
      };
    }
    return mergedOptions;
  }

  /// GET 요청
  Future<T?> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: requiresAuth ? _authOptions() : null,
      );
      if (response.statusCode == 200 && fromJson != null) {
        return fromJson(response.data);
      }
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST 요청
  Future<T?> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        options: requiresAuth ? _authOptions() : null,
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && fromJson != null) {
        return fromJson(response.data);
      }
      return response.statusCode == 200 || response.statusCode == 201 ? response.data : null;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// PUT 요청
  Future<bool> put(
    String path, {
    dynamic data,
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        options: requiresAuth ? _authOptions() : null,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// PATCH 요청
  Future<bool> patch(
    String path, {
    dynamic data,
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        options: requiresAuth ? _authOptions() : null,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE 요청
  Future<bool> delete(
    String path, {
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        options: requiresAuth ? _authOptions() : null,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
