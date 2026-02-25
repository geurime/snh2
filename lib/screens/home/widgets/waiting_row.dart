import 'package:flutter/material.dart';
import '../../../constants/colors.dart';

class WaitingRow extends StatelessWidget {
  final String label;
  final int? count;

  const WaitingRow({
    super.key,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.black.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          count?.toString() ?? '-',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          '대',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}
