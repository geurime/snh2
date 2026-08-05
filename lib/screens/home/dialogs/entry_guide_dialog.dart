import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/colors.dart';
import '../../../constants/spacing.dart';
import '../../../constants/typography.dart';
import '../../../widgets/pressable.dart';

/// 앱을 열면 처음 보는 화면.
///
/// 기존 고객도 안 들어오고 입구 앞에 서서 기다리는 일이 잦아서 띄운다.
/// 즉 안내가 아니라 **행동을 바꾸려는 화면**이라, 콘 사진 두 장이 본문이다.
///
/// 색은 하나만 쓴다 — `입장 불가`에만. 가능한 쪽은 검정으로 두면
/// 오렌지가 붙은 쪽이 "막힌 경우"라는 게 한눈에 갈린다.
class EntryGuideDialog extends StatefulWidget {
  const EntryGuideDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hide = prefs.getBool('hideEntryGuide') ?? false;
    if (!hide && context.mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const EntryGuideDialog(),
      );
    }
  }

  @override
  State<EntryGuideDialog> createState() => _EntryGuideDialogState();
}

class _EntryGuideDialogState extends State<EntryGuideDialog> {
  bool _dontShowAgain = false;

  Future<void> _close() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hideEntryGuide', true);
    }
    if (mounted) Navigator.pop(context);
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
              '진입 안내',
              style: AppText.screenTitle.copyWith(
                color: AppColors.gray900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              '입구의 콘 배치를 확인해주세요',
              style: AppText.body.copyWith(color: AppColors.gray600),
            ),
            const SizedBox(height: AppSpace.lg),
            const Row(
              children: [
                Expanded(
                  child: _Cone(
                    asset: 'assets/cone_open.jpeg',
                    label: '입장 가능',
                    isBlocked: false,
                  ),
                ),
                SizedBox(width: AppSpace.md),
                Expanded(
                  child: _Cone(
                    asset: 'assets/cone_blocked.jpeg',
                    label: '입장 불가',
                    isBlocked: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              '콘이 없으면 양쪽 어디든 바로 들어오세요.\n'
              '빈 충전기가 있으면 줄 서지 않으셔도 됩니다.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                color: AppColors.gray900,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            _DontShowAgain(
              checked: _dontShowAgain,
              onChanged: (v) => setState(() => _dontShowAgain = v),
            ),
            const SizedBox(height: AppSpace.md),
            Pressable(
              onTap: _close,
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

class _Cone extends StatelessWidget {
  final String asset;
  final String label;
  final bool isBlocked;

  const _Cone({
    required this.asset,
    required this.label,
    required this.isBlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: Image.asset(asset, fit: BoxFit.cover),
        ),
        const SizedBox(height: AppSpace.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.xs + 2,
          ),
          decoration: BoxDecoration(
            color: isBlocked ? AppColors.orangeTint : AppColors.gray100,
            borderRadius: BorderRadius.circular(AppSpace.sm),
          ),
          child: Text(
            label,
            style: AppText.label.copyWith(
              fontWeight: FontWeight.w700,
              color: isBlocked ? AppColors.orangeText : AppColors.gray900,
            ),
          ),
        ),
      ],
    );
  }
}

class _DontShowAgain extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool> onChanged;

  const _DontShowAgain({required this.checked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.97,
      onTap: () => onChanged(!checked),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.fast),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? AppColors.orange : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked ? AppColors.orange : AppColors.gray300,
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 15, color: AppColors.card)
                  : null,
            ),
            const SizedBox(width: AppSpace.sm),
            Text(
              '다시 보지 않기',
              style: AppText.body.copyWith(color: AppColors.gray600),
            ),
          ],
        ),
      ),
    );
  }
}
