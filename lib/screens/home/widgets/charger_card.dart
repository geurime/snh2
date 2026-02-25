import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../providers/station_provider.dart';
import 'charger_status.dart';
import 'carwash_badge.dart';

class ChargerCard extends StatelessWidget {
  const ChargerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.watch<StationProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ChargerStatusWidget(
                  name: 'B',
                  status: stationProvider.chargerB,
                ),
              ),
              Container(
                width: 1,
                height: 80,
                color: AppColors.black.withOpacity(0.1),
              ),
              Expanded(
                child: ChargerStatusWidget(
                  name: 'A',
                  status: stationProvider.chargerA,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '세차장',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 8),
              CarwashBadge(status: stationProvider.carWashStatus),
            ],
          ),
        ],
      ),
    );
  }
}
