import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/colors.dart';
import '../../../services/hydrogen_api.dart';
import 'waiting_row.dart';

class StatusCard extends StatelessWidget {
  final IntegratedStatus? status;
  final VoidCallback onInfoTap;

  const StatusCard({
    super.key,
    required this.status,
    required this.onInfoTap,
  });

  String _calculateWaitTime() {
    final waitMinutes = status?.estimatedWaitMinutes;
    if (waitMinutes == null) return '-';
    return waitMinutes.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '충전소 현황',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    WaitingRow(label: '승용', count: status?.waitingCars),
                    const SizedBox(height: 4),
                    WaitingRow(label: '버스', count: status?.waitingBuses),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.black.withOpacity(0.1),
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '예상 대기',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.black.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: onInfoTap,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(
                              LucideIcons.info,
                              size: 15,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _calculateWaitTime(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '분',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
