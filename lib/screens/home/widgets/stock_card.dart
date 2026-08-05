import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/spacing.dart';
import '../../../constants/strings.dart';
import '../../../constants/typography.dart';

/// 왼쪽은 오늘 T/T가 더 오는가, 오른쪽은 지금 탱크에 얼마나 있는가.
///
/// 근거가 다른 두 사실이라 라벨을 각각 단다. 붙여두면 "168이라서 여유있다"로
/// 오독되는데, 실제로 여유의 근거는 T/T가 더 들어온다는 사실이다.
///
/// 잔압을 게이지로 환산하지 않는다 — 시작 180~190, 마감 55~70으로 양쪽이
/// 매번 달라서 채움률이 거짓말이 된다. 숫자로만 보여준다.
///
/// 마지막 T/T는 **글자 색**으로 알린다. 관리 화면 충전기 행은 배경을 쓰는데,
/// 거기는 4줄 목록에서 한 줄을 찾아야 해서 배경이 유리하다.
/// 여기는 카드가 하나뿐이라 찾을 필요가 없고, 틴트 배경에 무채색 글자를 얹으면
/// 반쯤만 물든 것처럼 어중간해진다.
class StockCard extends StatelessWidget {
  final bool isLastTT;
  final int? pressure;

  const StockCard({
    super.key,
    required this.isLastTT,
    required this.pressure,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isLastTT ? AppColors.orangeText : AppColors.gray900;

    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.fast),
      curve: AppMotion.curve,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.card),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpace.lg),
                child: _Column(
                  label: S.stockTitle,
                  child: Text(
                    isLastTT ? S.stockLast : S.stockEnough,
                    style: AppText.title.copyWith(color: accent),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.gray300),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpace.lg),
                child: _Column(
                  // 마감 잔압은 잔압에 대한 설명이라 라벨 옆에 붙인다.
                  // 값 아래에 두면 없던 줄이 생겨 카드 세로 길이가 변한다.
                  label: isLastTT
                      ? '${S.pressureTitle} · ${S.closingAt(kClosingPressureBar)}'
                      : S.pressureTitle,
                  child: _Pressure(pressure: pressure, color: accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Column extends StatelessWidget {
  final String label;
  final Widget child;

  const _Column({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.label.copyWith(color: AppColors.gray600),
        ),
        const SizedBox(height: AppSpace.xs),
        child,
      ],
    );
  }
}

class _Pressure extends StatelessWidget {
  final int? pressure;
  final Color color;

  const _Pressure({required this.pressure, required this.color});

  @override
  Widget build(BuildContext context) {
    // 좁은 반쪽 칸이라 글꼴 확대 시 넘칠 수 있다.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            pressure?.toString() ?? '-',
            style: AppText.number.copyWith(color: color),
          ),
          const SizedBox(width: 2),
          Text(
            S.pressureUnit,
            style: AppText.label.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
