import 'package:flutter/material.dart';

/// 색은 E1 공식 오렌지 한 계열 + 무채색 4단계가 전부다.
///
/// 오렌지는 "지금 봐야 하는 것"에만 붙는다. 브랜드 장식으로 쓰지 않는다.
/// 초록/빨강을 없앤 이유는 CLAUDE.md 참조.
abstract final class AppColors {
  // ── 브랜드 — E1 CI 규정 (Pantone 1665C · CMYK C0 M72 Y100 K3) ──
  /// 대비 3.37:1 — 18px 이상 굵은 글씨와 아이콘에만.
  static const orange = Color(0xFFE96220);

  /// 대비 5.15:1 — 작은 글씨용 오렌지.
  static const orangeText = Color(0xFFBA4A12);

  /// 배너 · 경고 카드 배경.
  static const orangeTint = Color(0xFFFDEFE9);

  // ── 중립 ──
  /// 대비 12.91:1 — 본문 · 히어로 숫자.
  static const gray900 = Color(0xFF30313A);

  /// 대비 5.31:1 — 보조 텍스트 · 캡션.
  static const gray600 = Color(0xFF6B6C77);

  /// 구분선.
  static const gray300 = Color(0xFFD6D7DC);

  /// 배경 (E1 Light Gray).
  static const gray100 = Color(0xFFF3F3F3);

  static const card = Color(0xFFFFFFFF);

  // ── 관리 화면 T/T 상태색 ──
  // 손님 화면은 오렌지 하나로 간다. 관리 화면 T/T만 예외인 이유:
  // 조회가 목적이고 3상태가 실제로 계속 도니까 "상시 켜진 신호" 문제가 없다.
  // 셋 다 대비 5.1~5.2:1로 맞춰 하나가 실수로 더 강조되지 않게 했다.
  static const stateInUse = orangeText; // 사용 중  5.15:1
  static const stateReady = Color(0xFF1E7E3C); // 대기    5.12:1
  static const stateEmpty = gray600; // 빈통    5.20:1

  // ── 구 API 호환 별칭 ──
  // 관리자·FAQ·매출 화면이 아직 참조한다. 해당 화면을 리디자인할 때 걷어낼 것.
  // 새 코드에서는 쓰지 말 것 — 아래 별칭 대신 위 토큰을 직접 참조한다.
  static const background = gray100; // → gray100
  static const black = gray900; // → gray900
  static const primary = orange; // → orange / orangeText
}
