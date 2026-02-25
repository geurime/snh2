import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../constants/colors.dart';
import 'skeleton_box.dart';

class StatusCardSkeleton extends StatelessWidget {
  const StatusCardSkeleton({super.key});

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
            const SkeletonBox(width: 80, height: 17),
            const SizedBox(height: 16),
            SizedBox(
              height: 64,
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkeletonBox(width: 56, height: 17),
                        SizedBox(height: 4),
                        SkeletonBox(width: 60, height: 38),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: AppColors.black.withOpacity(0.1),
                  ),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkeletonBox(width: 56, height: 17),
                        SizedBox(height: 4),
                        SkeletonBox(width: 60, height: 38),
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
