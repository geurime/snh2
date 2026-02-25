import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../services/hydrogen_api.dart';
import 'charger_button.dart';
import 'carwash_button.dart';

class StationStatusSection extends StatelessWidget {
  final ChargerStatus chargerA;
  final ChargerStatus chargerB;
  final CarWashStatus carWashStatus;
  final VoidCallback onChargerATap;
  final VoidCallback onChargerBTap;
  final VoidCallback onCarWashTap;

  const StationStatusSection({
    super.key,
    required this.chargerA,
    required this.chargerB,
    required this.carWashStatus,
    required this.onChargerATap,
    required this.onChargerBTap,
    required this.onCarWashTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: ChargerButton(
              name: 'A',
              status: chargerA,
              onTap: onChargerATap,
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.black.withOpacity(0.1),
          ),
          Expanded(
            child: ChargerButton(
              name: 'B',
              status: chargerB,
              onTap: onChargerBTap,
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.black.withOpacity(0.1),
          ),
          Expanded(
            child: CarwashButton(
              status: carWashStatus,
              onTap: onCarWashTap,
            ),
          ),
        ],
      ),
    );
  }
}
