import 'package:firebase_analytics/firebase_analytics.dart';

/// 화면을 **지울지 말지 판단할 때만** 쓴다.
///
/// 손님 화면은 재는 게 없다 — 설치가 전원 현장 QR이라 유입 경로가 하나고,
/// 대기시간을 보러 오는 것도 이미 안다. 잴 게 없는 곳에 이벤트를 심으면
/// 나중에 어떤 숫자가 의미 있는지 구분이 안 된다.
///
/// 지금 재는 건 매출 추이 하나뿐이다. 직원이 실제로 여는지 몰라서
/// 없앨 근거도 남길 근거도 없는 상태다.
abstract final class Analytics {
  static final _instance = FirebaseAnalytics.instance;

  /// 실패해도 앱이 멈추면 안 된다. 옥외에서 전파가 끊기는 환경이다.
  static Future<void> _log(String name) async {
    try {
      await _instance.logEvent(name: name);
    } catch (_) {
      // 통계는 없어도 되는 정보다.
    }
  }

  /// 관리 화면에서 매출 추이로 들어갔다.
  static Future<void> salesReportOpened() => _log('sales_report_opened');
}
