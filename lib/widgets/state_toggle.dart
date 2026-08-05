import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';
import '../constants/typography.dart';
import 'pressable.dart';

/// 두 상태 중 하나를 고르는 토글. 흰 썸이 옆으로 미끄러진다.
///
/// 현재 값만 보이는 칩과 다르다 — 두 상태가 다 보이니 **누르면 어디로 갈지가
/// 형태에 있다.** 하단 모드 전환 스위치와 같은 형태라 앱 안에서 "둘 중 고르기"는
/// 전부 이 모양이다.
///
/// 3상태 순환을 쓰지 않는 이유: 중간값이 서버에 저장되면서 손님 화면에 나간다.
class StateToggle extends StatelessWidget {
  static const _width = 116.0;
  static const _height = 40.0;
  static const _pad = 3.0;

  final String labelA;
  final String labelB;

  /// true면 오른쪽(B)이 선택된 상태.
  final bool isB;

  /// 선택된 라벨 색. 지정하지 않으면 먹색.
  final Color? colorA;
  final Color? colorB;

  final ValueChanged<bool>? onChanged;

  const StateToggle({
    super.key,
    required this.labelA,
    required this.labelB,
    required this.isB,
    this.colorA,
    this.colorB,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.94,
      onTap: onChanged == null ? null : () => onChanged!(!isB),
      child: SizedBox(
        width: _width,
        height: _height,
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const SizedBox.expand(),
            ),
            Padding(
              padding: const EdgeInsets.all(_pad),
              child: AnimatedAlign(
                duration: AppMotion.of(context, AppMotion.snap),
                curve: AppMotion.snapCurve,
                alignment: isB ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: (_width - _pad * 2) / 2,
                  height: _height - _pad * 2,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2430313A),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _Label(text: labelA, isOn: !isB, color: colorA),
                _Label(text: labelB, isOn: isB, color: colorB),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final bool isOn;
  final Color? color;

  const _Label({required this.text, required this.isOn, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: AppMotion.of(context, AppMotion.fast),
          curve: AppMotion.curve,
          style: AppText.label.copyWith(
            fontWeight: isOn ? FontWeight.w700 : FontWeight.w400,
            color: isOn ? (color ?? AppColors.gray900) : AppColors.gray600,
          ),
          child: Text(text),
        ),
      ),
    );
  }
}
