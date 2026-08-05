import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../constants/colors.dart';
import '../../../constants/spacing.dart';
import 'skeleton_box.dart';

/// 첫 로딩에만 보인다. 갱신 실패 시엔 직전 값을 유지하므로 다시 나타나지 않는다.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray300,
      highlightColor: AppColors.gray100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Card(
            children: [
              SkeletonBox(width: 74, height: 15, borderRadius: 4),
              SizedBox(height: AppSpace.md),
              SkeletonBox(width: 196, height: 44, borderRadius: 6),
              SizedBox(height: AppSpace.md),
              SkeletonBox(width: 128, height: 13, borderRadius: 4),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          _Card(
            children: [
              SkeletonBox(width: 58, height: 12, borderRadius: 4),
              SizedBox(height: AppSpace.sm),
              SkeletonBox(width: 104, height: 22, borderRadius: 5),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;

  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    // 높이를 고정하면 안쪽 내용이 조금만 늘어도 넘친다. 내용이 높이를 정하게 둔다.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
