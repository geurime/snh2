// 앱 전역 데이터 (간단한 상태 관리)
class AppData {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  String announcement = '1/25(토) 오후 2시~4시 정기점검 예정';

  // 공지 변경 리스너
  final List<Function()> _listeners = [];

  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  void setAnnouncement(String text) {
    announcement = text;
    for (var listener in _listeners) {
      listener();
    }
  }
}
