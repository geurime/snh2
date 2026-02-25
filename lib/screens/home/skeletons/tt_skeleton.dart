import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../constants/colors.dart';
import 'skeleton_box.dart';

class TTCardSkeleton extends StatelessWidget {
  const TTCardSkeleton({super.key});

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
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 56, height: 17),
                SkeletonBox(width: 18, height: 18),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkeletonBox(width: 28, height: 17),
                        SizedBox(height: 4),
                        SkeletonBox(width: 60, height: 29),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: AppColors.black.withOpacity(0.1),
                  ),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkeletonBox(width: 28, height: 17),
                        SizedBox(height: 4),
                        SkeletonBox(width: 100, height: 22),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
