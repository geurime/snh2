import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/spacing.dart';
import '../../../constants/strings.dart';
import '../../../constants/typography.dart';
import '../../../widgets/pressable.dart';

/// 영업이 끝났을 때 화면을 막고 뜬다.
///
/// 이 앱에서 비용이 가장 큰 실패가 헛걸음이라 `barrierDismissible: false`다.
/// 아이콘은 두지 않는다 — 문구가 이미 "끝났다"를 말하고, 모달로 화면을 막는 것
/// 자체가 최고 강도라 그림을 더할 이유가 없다.
class ClosedDialog extends StatelessWidget {
  const ClosedDialog({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ClosedDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.card),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              S.heroClosed,
              textAlign: TextAlign.center,
              style: AppText.hero.copyWith(color: AppColors.orange),
            ),
            // 운영시간 한 줄이면 "내일 7시 반부터"가 읽히고 마감 시각까지 알려준다.
            // "내일 07:30에 열어요"를 따로 두면 07:30이 두 줄에 겹친다.
            const SizedBox(height: AppSpace.sm),
            Text(
              S.openHours,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.gray600),
            ),
            const SizedBox(height: AppSpace.xl),
            Pressable(
              onTap: () => Navigator.pop(context),
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  '확인',
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.card,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
