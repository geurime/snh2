import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../services/hydrogen_api.dart';

class TTStatusItem extends StatelessWidget {
  final String name;
  final TTStatus status;
  final VoidCallback? onTap;

  const TTStatusItem({
    super.key,
    required this.name,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case TTStatus.empty:
        color = AppColors.black.withOpacity(0.3);
        label = '빈통';
        break;
      case TTStatus.standby:
        color = const Color(0xFF4CAF50);
        label = '대기';
        break;
      case TTStatus.inUse:
        color = AppColors.primary;
        label = '사용 중';
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              'T/T $name',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.black.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
