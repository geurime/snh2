import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/colors.dart';
import '../../../constants/spacing.dart';
import '../../../constants/typography.dart';

/// 이상 상태와 공지를 알리는 배너. 히어로 위에 놓인다.
///
/// 대기시간이 왜 긴지를 설명하는 정보이므로 숫자보다 먼저 읽혀야 납득이 된다.
class AlertBanner extends StatelessWidget {
  final String title;
  final String? detail;
  final IconData icon;

  const AlertBanner({
    super.key,
    required this.title,
    this.detail,
    this.icon = LucideIcons.alertTriangle,
  });

  /// 공지는 문제가 아니라 알림이므로 아이콘만 다르다.
  const AlertBanner.notice({
    super.key,
    required this.title,
    this.detail,
  }) : icon = LucideIcons.info;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.orangeTint,
        borderRadius: BorderRadius.circular(AppRadius.banner),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: AppIcon.lg, color: AppColors.orangeText),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 앱이 손님에게 하는 말이라 손글씨. 아래 설명은 데이터 톤으로 둔다.
                Text(
                  title,
                  style: AppText.title.copyWith(color: AppColors.orangeText),
                ),
                if (detail != null)
                  Text(
                    detail!,
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
