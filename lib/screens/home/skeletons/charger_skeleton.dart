import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../constants/colors.dart';
import 'skeleton_box.dart';

class ChargerCardSkeleton extends StatelessWidget {
  const ChargerCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.black.withOpacity(0.08),
        highlightColor: AppColors.black.withOpacity(0.02),
        child: Column(
          children: [
            SizedBox(
              height: 106,
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkeletonBox(width: 56, height: 17),
                        SizedBox(height: 8),
                        SkeletonBox(width: 48, height: 48, borderRadius: 12),
                        SizedBox(height: 8),
                        SkeletonBox(width: 44, height: 19),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 80,
                    color: AppColors.black.withOpacity(0.1),
                  ),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkeletonBox(width: 56, height: 17),
                        SizedBox(height: 8),
                        SkeletonBox(width: 48, height: 48, borderRadius: 12),
                        SizedBox(height: 8),
                        SkeletonBox(width: 44, height: 19),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const SkeletonBox(width: 100, height: 16),
          ],
        ),
      ),
    );
  }
}
