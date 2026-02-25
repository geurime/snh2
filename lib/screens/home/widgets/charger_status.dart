import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/colors.dart';
import '../../../services/hydrogen_api.dart';

class ChargerStatusWidget extends StatelessWidget {
  final String name;
  final ChargerStatus status;

  const ChargerStatusWidget({
    super.key,
    required this.name,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case ChargerStatus.operating:
        color = const Color(0xFF4CAF50);
        icon = LucideIcons.fuel;
        break;
      case ChargerStatus.broken:
        color = const Color(0xFFE57373);
        icon = LucideIcons.ban;
        break;
      case ChargerStatus.maintenance:
        color = const Color(0xFFFFA726);
        icon = LucideIcons.wrench;
        break;
    }

    return Column(
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          status.displayName,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Badasseugi',
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
