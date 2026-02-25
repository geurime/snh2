import 'package:dio/dio.dart';

/// API 호출 중 발생하는 예외
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  factory ApiException.fromDioException(DioException e) {
    String message;
    int? statusCode = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = '서버 응답 시간 초과';
        break;
      case DioExceptionType.connectionError:
        message = '네트워크 연결 실패';
        break;
      case DioExceptionType.badResponse:
        message = _getMessageFromStatusCode(statusCode);
        break;
      case DioExceptionType.cancel:
        message = '요청이 취소됨';
        break;
      default:
        message = '알 수 없는 오류';
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      originalError: e,
    );
  }

  static String _getMessageFromStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '잘못된 요청';
      case 401:
        return '인증 필요';
      case 403:
        return '권한 없음';
      case 404:
        return '리소스 없음';
      case 500:
        return '서버 오류';
      default:
        return '요청 실패 ($statusCode)';
    }
  }

  @override
  String toString() => 'ApiException: $message (statusCode: $statusCode)';
}
