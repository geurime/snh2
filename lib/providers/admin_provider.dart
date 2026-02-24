import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminProvider extends ChangeNotifier {
  static const String _adminModeKey = 'admin_mode';
  static const String _adminPassword = '01130701';

  bool _isAdminMode = false;

  bool get isAdminMode => _isAdminMode;

  AdminProvider() {
    _loadAdminMode();
  }

  Future<void> _loadAdminMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isAdminMode = prefs.getBool(_adminModeKey) ?? false;
    notifyListeners();
  }

  Future<bool> login(String password) async {
    if (password == _adminPassword) {
      _isAdminMode = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_adminModeKey, true);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _isAdminMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adminModeKey, false);
    notifyListeners();
  }
}
