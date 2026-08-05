import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/colors.dart';
import '../../../constants/spacing.dart';
import '../../../constants/strings.dart';
import '../../../constants/typography.dart';
import '../../../services/hydrogen_api.dart';

/// 임계값이 있는 감시 지표. 평소엔 조용한 한 줄, 넘으면 카드로 커진다.
///
/// Before는 항상 같은 크기로 맨 위에 떠 있어서 65를 넘었는지 직원이 외워서
/// 비교해야 했다. 늘 떠 있으면 정작 넘었을 때 눈에 안 들어온다.
class MetricBar extends StatelessWidget {
  final MonthlyPressureStats? pressure;
  final MonthlyLossStats? loss;

  const MetricBar({super.key, required this.pressure, required this.loss});

  double? get _pressureValue =>
      (pressure?.recordCount ?? 0) > 0 ? pressure!.averagePressure : null;

  double? get _lossValue =>
      (loss?.recordCount ?? 0) > 0 ? loss!.averageLossRate.toDouble() : null;

  bool get _pressureOver =>
      _pressureValue != null && _pressureValue! > kMaxAveragePressureBar;

  bool get _lossOver =>
      _lossValue != null && _lossValue!.abs() > kMaxLossRatePercent;

  @override
  Widget build(BuildContext context) {
    final warnings = <Widget>[
      if (_pressureOver)
        _Warning(
          title: '${S.metricPressure} ${_fmt(_pressureValue!)}bar',
          detail: S.pressureOver(kMaxAveragePressureBar),
        ),
      if (_lossOver)
        _Warning(
          title: '${S.metricLoss} ${_fmt(_lossValue!)}%',
          detail: S.lossOver(kMaxLossRatePercent),
        ),
    ];

    // 정상인 것만 한 줄로 남긴다. 넘은 건 위 카드가 이미 말했다.
    final quiet = <(String, String)>[
      if (_pressureValue != null && !_pressureOver)
        (S.metricPressure, '${_fmt(_pressureValue!)}bar'),
      if (_lossValue != null && !_lossOver)
        (S.metricLoss, '${_fmt(_lossValue!)}%'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final w in warnings) ...[w, const SizedBox(height: AppSpace.md)],
        if (quiet.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: AppSpace.xs),
            child: _QuietLine(items: quiet),
          ),
      ],
    );
  }

  /// 소수점이 없으면 정수로 — 59.0bar보다 59bar가 읽기 쉽다.
  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

/// 라벨은 흐리게, 값은 진하게 — 홈의 근거 줄과 같은 처리다.
/// 여기서 봐야 할 건 숫자지 "평균 잔압"이라는 말이 아니다.
class _QuietLine extends StatelessWidget {
  final List<(String, String)> items;

  const _QuietLine({required this.items});

  @override
  Widget build(BuildContext context) {
    final base = AppText.label.copyWith(color: AppColors.gray600);
    final value = base.copyWith(
      color: AppColors.gray900,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) TextSpan(text: ' · ', style: base),
            TextSpan(text: '${items[i].$1} ', style: base),
            TextSpan(text: items[i].$2, style: value),
          ],
        ],
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  final String title;
  final String detail;

  const _Warning({required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.orangeTint,
        borderRadius: BorderRadius.circular(AppRadius.banner),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              LucideIcons.alertTriangle,
              size: AppIcon.lg,
              color: AppColors.orangeText,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.title.copyWith(color: AppColors.orangeText),
                ),
                Text(
                  detail,
                  style: AppText.label.copyWith(color: AppColors.gray600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
