import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/colors.dart';
import '../../../constants/spacing.dart';
import '../../../constants/strings.dart';
import '../../../constants/typography.dart';
import '../../../widgets/pressable.dart';

/// 데이터를 한 번도 못 받았을 때. 모르는 것을 아는 척하지 않는다.
///
/// 이전에는 값이 없으면 `isOperating ?? false`로 떨어져서 영업 중인데도
/// "오늘 영업 끝났어요"가 떴다. 옥외라 전파가 끊기는 일이 흔한데,
/// 그때마다 앱이 헛걸음을 만들어내는 셈이었다.
class LoadFailedCard extends StatelessWidget {
  final VoidCallback onRetry;

  const LoadFailedCard({super.key, required this.onRetry});

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
        children: [
          Row(
            children: [
              const Icon(LucideIcons.wifiOff, size: AppIcon.lg, color: AppColors.gray600),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  S.loadFailedTitle,
                  style: AppText.title.copyWith(color: AppColors.gray900),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            S.loadFailedBody,
            style: AppText.label.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: AppSpace.lg),
          Pressable(
            onTap: onRetry,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.orangeTint,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                S.retry,
                style: AppText.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.orangeText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
