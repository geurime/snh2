import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../services/hydrogen_api.dart';

class AdminProvider extends ChangeNotifier {
  static const String _adminModeKey = 'admin_mode';
  static const String _tokenKey = 'jwt_token';
  static const String _baseUrl = 'https://snh2-production.up.railway.app/api';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  bool _isAdminMode = false;
  String? _accessToken;

  bool get isAdminMode => _isAdminMode;
  String? get accessToken => _accessToken;

  AdminProvider() {
    _loadAdminMode();
  }

  Future<void> _loadAdminMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isAdminMode = prefs.getBool(_adminModeKey) ?? false;

    // 토큰 복원
    if (_isAdminMode) {
      _accessToken = await _secureStorage.read(key: _tokenKey);
      // 토큰이 없으면 로그아웃 상태로 변경
      if (_accessToken == null) {
        _isAdminMode = false;
        _accessToken = null;
        await prefs.setBool(_adminModeKey, false);
        await _secureStorage.delete(key: _tokenKey);
      } else {
        // API 서비스에 토큰 동기화
        HydrogenApiService().setAccessToken(_accessToken);
      }
    }

    notifyListeners();
  }

  Future<bool> login(String password) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/login',
        data: {'password': password},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data['access_token'] != null) {
        _accessToken = response.data['access_token'];
        _isAdminMode = true;

        // 토큰 저장
        await _secureStorage.write(key: _tokenKey, value: _accessToken);

        // API 서비스에 토큰 동기화
        HydrogenApiService().setAccessToken(_accessToken);

        // 관리자 모드 상태 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_adminModeKey, true);

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('[AdminProvider] Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _isAdminMode = false;
    _accessToken = null;

    // 토큰 삭제
    await _secureStorage.delete(key: _tokenKey);

    // API 서비스에서 토큰 제거
    HydrogenApiService().setAccessToken(null);

    // 관리자 모드 상태 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adminModeKey, false);

    notifyListeners();
  }

  /// 토큰이 유효한지 확인 (만료 시간 포함)
  bool get hasValidToken {
    if (_accessToken == null || _accessToken!.isEmpty) {
      return false;
    }
    return !_isTokenExpired(_accessToken!);
  }

  /// JWT 토큰 만료 여부 확인
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> data = json.decode(decoded);

      final exp = data['exp'] as int?;
      if (exp == null) return true;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      debugPrint('[AdminProvider] Token parse error: $e');
      return true;
    }
  }
}
