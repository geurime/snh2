import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/spacing.dart';
import '../../../constants/strings.dart';
import '../../../constants/typography.dart';
import '../../../services/hydrogen_api.dart';
import '../../../widgets/state_toggle.dart';

/// 실물이 나란히 있는 두 통이라 좌우로 둔다.
///
/// 직원이 여기서 보는 건 "지금 어디 쓰고 있고, 나머지는 찼나 비었나"다.
/// 조회가 목적이라 색으로 구분한다 — 3상태가 실제로 계속 도니까 손님 화면에서
/// 초록을 죽인 이유("상시 켜진 신호")가 여기엔 해당하지 않는다.
class TTSection extends StatelessWidget {
  final TTStatus ttA;
  final TTStatus ttB;
  final ValueChanged<String> onToggle;

  const TTSection({
    super.key,
    required this.ttA,
    required this.ttB,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpace.xs, bottom: AppSpace.sm),
          child: Text(
            S.sectionTT,
            style: AppText.tag.copyWith(color: AppColors.gray600),
          ),
        ),
        // 실물 탱크 배치를 따른다 — 화면 순서가 현장과 어긋나면 헷갈린다.
        Row(
          children: [
            Expanded(child: _Cell(name: 'B', status: ttB, onToggle: onToggle)),
            const SizedBox(width: AppSpace.md),
            Expanded(child: _Cell(name: 'A', status: ttA, onToggle: onToggle)),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String name;
  final TTStatus status;
  final ValueChanged<String> onToggle;

  const _Cell({
    required this.name,
    required this.status,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.banner + 2),
      ),
      child: Column(
        children: [
          Text(
            '${S.sectionTT} $name',
            style: AppText.label.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: AppSpace.sm + 2),
          // 사용 중은 백엔드가 잔압으로 자동 판정한다. 직원이 바꿀 수 없으니
          // 토글을 아예 안 보여준다 — 눌러도 반응 없으면 고장으로 오해한다.
          if (status == TTStatus.inUse)
            SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  S.ttInUse,
                  style: AppText.title.copyWith(color: AppColors.stateInUse),
                ),
              ),
            )
          else
            StateToggle(
              labelA: S.ttEmpty,
              labelB: S.ttReady,
              isB: status == TTStatus.standby,
              colorA: AppColors.stateEmpty,
              colorB: AppColors.stateReady,
              onChanged: (_) => onToggle(name),
            ),
        ],
      ),
    );
  }
}
