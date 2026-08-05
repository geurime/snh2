import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/colors.dart';
import '../../../constants/spacing.dart';
import '../../../constants/strings.dart';
import '../../../constants/typography.dart';
import '../../faq_screen.dart';
import '../../../widgets/pressable.dart';

/// 홈 하단에 병합된 충전소 안내. 별도 탭이었던 화면을 여기로 흡수했다.
///
/// 설치가 사실상 전원 현장 QR이라 처음 오는 사람이 없다. 주소·길찾기 같은
/// 유치용 정보는 두지 않고, "올 사람이 오면서 확인하는 것"만 남긴다.
class StationInfo extends StatelessWidget {
  const StationInfo({super.key});

  void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.gray900,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpace.xs, bottom: AppSpace.sm),
          child: Text(
            S.infoTitle,
            style: AppText.tag.copyWith(color: AppColors.gray600),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.gray300),
        const SizedBox(height: AppSpace.xs),
        const _InfoRow(icon: LucideIcons.clock, value: S.openHours),
        const _InfoRow(icon: LucideIcons.creditCard, value: S.price),
        _InfoRow(
          icon: LucideIcons.landmark,
          value: S.account,
          onTap: () {
            Clipboard.setData(const ClipboardData(text: S.accountNumber));
            _notify(context, S.accountCopied);
          },
        ),
        const _InfoRow(icon: LucideIcons.gift, value: S.benefit),
        // FAQ는 전화를 대신한다. 그 전화가 수소 전용도 아닌 대표번호라 손님은
        // 헤매고 직원은 응대 부담이 생긴다. 위에서 아래로 읽히므로 순서 자체가
        // 강조이고, 따로 장식할 필요가 없다.
        _InfoRow(
          icon: LucideIcons.helpCircle,
          value: S.faq,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const FaqScreen()),
          ),
        ),
        _InfoRow(
          icon: LucideIcons.phone,
          value: S.phone,
          onTap: () => launchUrl(Uri.parse('tel:${S.phone}')),
        ),
        const SizedBox(height: AppSpace.xxl),
        const _Footer(),
      ],
    );
  }
}

/// 안내 탭을 없애면서 같이 사라졌던 항목. 스토어 심사에도 필요하다.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => launchUrl(
        Uri.parse(S.privacyUrl),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        child: Text(
          S.privacy,
          style: AppText.label.copyWith(color: AppColors.gray600),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Container(
      constraints: const BoxConstraints(minHeight: 48),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xs,
        vertical: AppSpace.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppIcon.md, color: AppColors.gray600),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              value,
              style: AppText.body.copyWith(color: AppColors.gray900),
            ),
          ),
          // 누를 수 있다는 신호라 구분선 색(gray300, 1.44:1)을 쓰면 안 된다.
          if (onTap != null)
            const Icon(LucideIcons.chevronRight, size: AppIcon.md, color: AppColors.gray600),
        ],
      ),
    );

    if (onTap == null) return row;
    return Pressable(scale: 0.99, onTap: onTap, child: row);
  }
}

