import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../providers/station_provider.dart';
import '../../../services/hydrogen_api.dart';
import 'tt_status_item.dart';

class TTStatusSection extends StatelessWidget {
  final MonthlyPressureStats? pressureStats;
  final MonthlyLossStats? lossStats;
  final TTStatus ttAStatus;
  final TTStatus ttBStatus;
  final Function(String name) onToggleTT;

  const TTStatusSection({
    super.key,
    required this.pressureStats,
    required this.lossStats,
    required this.ttAStatus,
    required this.ttBStatus,
    required this.onToggleTT,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '평균 잔압',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.black.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pressureStats != null && pressureStats!.recordCount > 0
                          ? '${pressureStats!.averagePressure.toStringAsFixed(2)}bar'
                          : '-',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.black.withOpacity(0.1),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '평균 손실률',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.black.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lossStats != null && lossStats!.recordCount > 0
                          ? '${lossStats!.averageLossRate}%'
                          : '-',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TTStatusItem(
                  name: 'B',
                  status: ttBStatus,
                  onTap: ttBStatus == TTStatus.inUse
                      ? null
                      : () => onToggleTT('B'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TTStatusItem(
                  name: 'A',
                  status: ttAStatus,
                  onTap: ttAStatus == TTStatus.inUse
                      ? null
                      : () => onToggleTT('A'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
