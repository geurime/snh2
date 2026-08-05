import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';
import '../constants/typography.dart';
import 'pressable.dart';

/// 바텀시트 헤더 — 좌측 제목, 우측 닫기.
///
/// 드래그 핸들(ㅡ)은 쓰지 않는다. 닫기의 시각 신호를 ✕ 하나로 단일화한다 —
/// 핸들과 ✕가 같이 있으면 닫는 경로가 둘로 보이는 소음이다.
/// 드래그로 내려 닫는 동작 자체는 그대로 살아 있다(아는 사람의 보조 제스처).
///
/// 이 시트들은 전부 입력 폼이라 키보드가 올라온다. 그 상태에선 드래그는 손이 멀고
/// 바깥 탭은 키보드에 가려서, 명시적 버튼이 없으면 닫는 경로가 사실상 막힌다.
class SheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SheetHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              // 시트는 화면 단위 맥락이라 화면 제목과 같은 단계를 쓴다.
              child: Text(
                title,
                // Pretendard 기본 행간이 1.193이라 그대로 두면 제목 아래에
                // 5px 넘는 여백이 생긴다. 부연과 한 쌍으로 읽히도록 조인다.
                style: AppText.screenTitle.copyWith(
                  color: AppColors.gray900,
                  height: 1.1,
                ),
              ),
            ),
            Pressable(
              scale: 0.88,
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.centerRight,
                child: const Icon(
                  LucideIcons.x,
                  size: AppIcon.lg,
                  color: AppColors.gray600,
                ),
              ),
            ),
          ],
        ),
        // 캡션이 아니라 실제 안내다 — 여기서만 알 수 있는 정보라 본문 크기로 둔다.
        // 명시 간격은 0이다. 폰트 메트릭이 만드는 여백만으로 충분하다.
        if (subtitle != null)
          Text(
            subtitle!,
            style: AppText.body.copyWith(
              color: AppColors.gray600,
              height: 1.35,
            ),
          ),
      ],
    );
  }
}
