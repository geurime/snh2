import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../services/hydrogen_api.dart';

class OperationBadge extends StatelessWidget {
  final IntegratedStatus? status;
  final bool isLoading;
  final VoidCallback onTap;

  const OperationBadge({
    super.key,
    required this.status,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOperating = status?.isOperating ?? false;
    final statusText = status?.operationStatus ?? '확인중';

    Color dotColor;
    if (isLoading) {
      dotColor = Colors.grey;
    } else if (isOperating) {
      dotColor = Colors.green;
    } else {
      dotColor = Colors.red;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isLoading ? '확인중' : statusText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
