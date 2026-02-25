import 'package:flutter/material.dart';
import '../../../constants/colors.dart';

class MealDisplay extends StatelessWidget {
  final String? lunchMenu;
  final String? dinnerMenu;

  const MealDisplay({
    super.key,
    this.lunchMenu,
    this.dinnerMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (lunchMenu != null)
          _buildMealRow('점심', lunchMenu!),
        if (lunchMenu != null && dinnerMenu != null)
          const SizedBox(height: 6),
        if (dinnerMenu != null)
          _buildMealRow('저녁', dinnerMenu!),
      ],
    );
  }

  Widget _buildMealRow(String label, String menu) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            menu,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
