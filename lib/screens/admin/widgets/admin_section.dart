import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/colors.dart';
import '../../../constants/spacing.dart';
import '../../../constants/typography.dart';
import '../../../widgets/pressable.dart';

/// 라벨 + 흰 카드 리스트. 관리 화면의 모든 묶음이 이 형태를 쓴다.
///
/// Before는 같은 성격("누르면 뭔가 일어남")을 색 박스·아이콘 그리드·아이콘 3칸
/// 세 형태로 나눠놨다. 매일 쓰는 도구 화면에서는 형태가 하나여야 위치만 외우면 된다.
class AdminSection extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const AdminSection({super.key, required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpace.xs, bottom: AppSpace.sm),
          child: Text(
            label,
            style: AppText.tag.copyWith(color: AppColors.gray600),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.banner + 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.banner + 2),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

/// 값을 오른쪽에 얹는 행. `›`는 화면·모달이 뜨는 것에만 쓴다.
class AdminRow extends StatelessWidget {
  final String label;

  /// 오른쪽에 붙는 현재 값. 없으면 화살표만.
  final String? value;

  /// 아직 처리하지 않아 지금 손봐야 하는 값이면 true.
  final bool isTodo;

  /// 값을 바꾸는 토글. 지정하면 화살표 대신 이게 들어간다.
  final Widget? control;

  /// 이상 상태라 줄 전체가 물들어야 하면 true.
  final bool isAlert;

  final VoidCallback? onTap;
  final bool showDivider;

  const AdminRow({
    super.key,
    required this.label,
    this.value,
    this.isTodo = false,
    this.control,
    this.isAlert = false,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final row = AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.fast),
      curve: AppMotion.curve,
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.sm,
      ),
      // 강조는 배경 하나로만. 라벨까지 물들이면 서로 잡아먹고, 틴트 위 오렌지
      // 글씨는 대비도 떨어진다. 상태 자체는 썸 위치가 이미 말한다.
      decoration: BoxDecoration(
        color: isAlert ? AppColors.orangeTint : AppColors.card,
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.gray100))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.body.copyWith(color: AppColors.gray900),
            ),
          ),
          if (control != null)
            control!
          else ...[
            if (value != null && value!.isNotEmpty)
              Text(
                value!,
                style: AppText.body.copyWith(
                  color: isTodo ? AppColors.orangeText : AppColors.gray900,
                  fontWeight: isTodo ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            const SizedBox(width: AppSpace.sm),
            const Icon(
              LucideIcons.chevronRight,
              size: AppIcon.md,
              color: AppColors.gray600,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return Pressable(scale: 0.99, onTap: onTap, child: row);
  }
}
