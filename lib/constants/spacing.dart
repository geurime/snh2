import 'package:flutter/material.dart';

/// 이 목록에 없는 값을 쓰지 않는다. `xxl + 2` 같은 산술은 매직 넘버와 같다.
/// 필요한 값이 없으면 여기에 이름을 붙여 추가한다.
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;

  /// 블록과 블록 사이 (현황 카드 ↔ 안내).
  static const section = 40.0;

  /// 카드 안쪽 여백. 모든 흰 카드가 같은 값을 쓴다.
  static const card = 24.0;
}

/// 아이콘은 옆에 붙는 글씨와 광학적으로 맞춰야 한다.
/// 크기를 제각각 쓰면 행마다 무게가 달라 보인다.
abstract final class AppIcon {
  /// 라벨·캡션(15) 옆.
  static const sm = 16.0;

  /// 본문(17) 옆. 안내 행과 화살표.
  static const md = 18.0;

  /// 제목(19) 옆. 배너와 카드 헤더.
  static const lg = 20.0;
}

abstract final class AppRadius {
  static const card = 20.0;
  static const banner = 14.0;
  static const chip = 12.0;
}

/// 그림자는 **떠 있는 것에만** 쓴다.
///
/// 바닥에 놓인 카드는 그림자를 쓰지 않는다 — 회색 배경(gray100) 위 흰 카드라
/// 면이 이미 갈리고, 아무 데나 쓰면 "떠 있다"는 신호 자체가 무의미해진다.
/// 색 규칙(오렌지 = 봐야 할 것)과 같은 논리다.
abstract final class AppShadow {
  /// 콘텐츠 위에 떠 있는 컨트롤 (모드 전환 스위치 등).
  static const floating = [
    BoxShadow(
      color: Color(0x1F30313A),
      blurRadius: 18,
      offset: Offset(0, 4),
    ),
  ];
}

/// 매일 여는 앱이라 진입 애니메이션은 매일 겪는 지연이 된다.
/// 상태가 바뀔 때만 움직인다.
abstract final class AppMotion {
  /// 색 · 투명도.
  static const fast = Duration(milliseconds: 150);

  /// 카드 등장 · 배너.
  static const base = Duration(milliseconds: 220);

  static const curve = Curves.easeOutCubic;

  /// 세그먼트 인디케이터 이동.
  /// 오버슛(easeOutBack)은 알약이 칸 밖으로 튀어나와 보여서 쓰지 않는다.
  /// 빠르게 출발해 부드럽게 멎는 것만으로 충분하다.
  static const snap = Duration(milliseconds: 260);
  static const snapCurve = Curves.easeOutCubic;

  /// 시스템에서 모션 최소화를 켰으면 전부 끈다.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}
