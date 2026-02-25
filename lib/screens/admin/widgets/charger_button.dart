import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/colors.dart';
import '../../../services/hydrogen_api.dart';

class ChargerButton extends StatelessWidget {
  final String name;
  final ChargerStatus status;
  final VoidCallback onTap;

  const ChargerButton({
    super.key,
    required this.name,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case ChargerStatus.operating:
        color = Colors.green;
        icon = LucideIcons.fuel;
        label = '정상';
        break;
      case ChargerStatus.broken:
        color = const Color(0xFFE57373);
        icon = LucideIcons.ban;
        label = '고장';
        break;
      case ChargerStatus.maintenance:
        color = const Color(0xFFFFA726);
        icon = LucideIcons.wrench;
        label = '점검중';
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '충전기 $name',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.black.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Badasseugi',
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
