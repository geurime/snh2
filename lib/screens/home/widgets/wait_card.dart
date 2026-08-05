import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/spacing.dart';
import '../../../constants/strings.dart';
import '../../../constants/typography.dart';

/// 이 앱의 히어로. 손님이 앱을 여는 이유가 이 숫자 하나다.
///
/// 숫자만 오렌지고 나머지 문장은 무채색이다. 문장 전체를 물들이면 다시 평평해진다.
/// "약"이 추정임을 흡수하므로 별도 면책 문구를 두지 않는다.
class WaitCard extends StatelessWidget {
  final bool isOperating;
  final int? waitMinutes;
  final int? waitingCars;
  final int? waitingBuses;

  const WaitCard({
    super.key,
    required this.isOperating,
    required this.waitMinutes,
    required this.waitingCars,
    required this.waitingBuses,
  });

  String? get _detail {
    final parts = <String>[
      if ((waitingCars ?? 0) > 0) S.cars(waitingCars!),
      if ((waitingBuses ?? 0) > 0) S.buses(waitingBuses!),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.card),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildContent(),
      ),
    );
  }

  List<Widget> _buildContent() {
    // 히어로의 "답"은 어떤 형태든 오렌지다. 숫자로 쓸 수 없을 때 문장이 그 자리를
    // 대신할 뿐이므로 역할이 같다. 근거는 무채색으로 둔다.
    if (!isOperating) {
      return [
        Text(S.heroClosed, style: AppText.hero.copyWith(color: AppColors.orange)),
        const SizedBox(height: AppSpace.xs),
        Text(
          S.heroOpensAt(S.openTime),
          style: AppText.label.copyWith(color: AppColors.gray600),
        ),
      ];
    }

    final minutes = waitMinutes;
    if (minutes == null) {
      // 값이 없는 것과 0은 다르다 — null을 "바로 충전"으로 내보내면
      // 추정 불가(추적 공백·충전기 전체 고장)가 호객 문구로 둔갑한다.
      // 15초 폴링이 돌므로 공백이 메워지면 화면도 스스로 돌아온다.
      return [
        Text(S.heroChecking, style: AppText.hero.copyWith(color: AppColors.orange)),
      ];
    }
    if (minutes <= 0) {
      // 이 문장은 0분을 말로 쓴 것이다 — 숫자 "12"와 같은 값 자리라 같은 색을 쓴다.
      // "0분 기다려요"가 어색해서 표기만 바꿨을 뿐이다.
      // 근거 줄은 없다 — "기다리는 차가 없어요"는 결론을 되풀이할 뿐이다.
      return [
        Text(S.heroEyebrow, style: AppText.lead.copyWith(color: AppColors.gray600)),
        Text(S.heroNoWait, style: AppText.hero.copyWith(color: AppColors.orange)),
      ];
    }

    return [
      Text(S.heroEyebrow, style: AppText.lead.copyWith(color: AppColors.gray600)),
      const SizedBox(height: 2),
      _WaitLine(minutes: minutes),
      if (_detail != null) ...[
        const SizedBox(height: AppSpace.xs),
        _DetailLine(text: _detail!),
      ],
    ];
  }
}

class _WaitLine extends StatelessWidget {
  final int minutes;

  const _WaitLine({required this.minutes});

  @override
  Widget build(BuildContext context) {
    final word = AppText.sentence.copyWith(color: AppColors.gray900);
    // 가로 한 줄이라 시스템 글꼴을 크게 키우면 넘친다. 세 자리(100분+)면 더 위험하다.
    // 이미 화면에서 가장 큰 요소라 여기서만 확대를 캡해도 손해가 없다.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(S.heroPrefix, style: word),
          const SizedBox(width: AppSpace.xs),
          Text(
            '$minutes',
            style: AppText.display.copyWith(color: AppColors.orange),
          ),
          const SizedBox(width: AppSpace.xs),
          Text(S.heroSuffix, style: word),
        ],
      ),
    );
  }
}

/// 대수는 근거일 뿐이라 조용하게 두되, 숫자만 진하게 해서 스캔이 되게 한다.
class _DetailLine extends StatelessWidget {
  final String text;

  const _DetailLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final base = AppText.label.copyWith(color: AppColors.gray600);
    final digits = base.copyWith(
      color: AppColors.gray900,
      fontWeight: FontWeight.w600,
    );

    final spans = <TextSpan>[];
    final buffer = StringBuffer();
    bool? wasDigit;

    void flush() {
      if (buffer.isEmpty) return;
      spans.add(TextSpan(
        text: buffer.toString(),
        style: wasDigit == true ? digits : base,
      ));
      buffer.clear();
    }

    for (final ch in text.split('')) {
      final isDigit = ch.codeUnitAt(0) >= 0x30 && ch.codeUnitAt(0) <= 0x39;
      if (wasDigit != null && isDigit != wasDigit) flush();
      wasDigit = isDigit;
      buffer.write(ch);
    }
    flush();

    return Text.rich(TextSpan(children: spans));
  }
}
