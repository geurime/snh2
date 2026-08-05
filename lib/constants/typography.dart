import 'package:flutter/material.dart';

/// 서체는 Pretendard 하나. 위계는 **크기 · 굵기 · 색** 세 가지로만 만든다.
///
/// 손글씨(Badasseugi)를 섞었더니 같은 px에서도 크기가 달라 보였다.
/// 잉크 높이는 거의 같은데(0.872 vs 0.862) 획이 얇고 둥글어서 생기는 차이라
/// px 보정으로는 안 잡힌다. 앱 아이콘·스플래시 같은 브랜딩 자리에만 남긴다.
///
/// 크기는 위로 갈수록 간격이 벌어진다 — 15 · 17 · 19 · 22 · 28 · 52.
/// 2px씩 촘촘히 끊으면 단계는 있어도 위계는 안 보인다.
abstract final class AppText {
  static const fontFamily = 'Pretendard';

  // ── 52 ── 히어로 숫자. 손님이 앱을 여는 이유.
  static const display = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.6,
    height: 1.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ── 28 ── 숫자로 쓸 수 없는 히어로. 문장이 숫자 자리를 대신한다.
  static const hero = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.25,
  );

  // ── 22 ──
  /// 잔압처럼 카드 안에서 대표가 되는 숫자.
  static const number = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// 히어로 숫자를 감싸는 말 ("약", "분 기다려요").
  static const sentence = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  /// 화면 제목. 카드 안 문구(19)와 성격이 달라 한 단계 위를 쓴다.
  static const screenTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  // ── 19 ── 판정 · 앱 제목 · 배너 제목.
  static const title = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  // ── 17 ── iOS 기본 본문과 같은 크기. 40~60대가 옥외에서 본다.
  static const body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
  );

  /// 히어로를 여는 말 ("지금 오시면"). 본문과 크기는 같고 굵기로 구분한다.
  static const lead = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  // ── 15 ── 라벨 · 캡션 · 근거. 더 내려가면 옥외에서 안 읽힌다.
  static const label = TextStyle(fontSize: 15, fontWeight: FontWeight.w400);

  /// 섹션 라벨 ("안내"). 같은 15지만 굵기로 라벨임을 표시한다.
  static const tag = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );
}
