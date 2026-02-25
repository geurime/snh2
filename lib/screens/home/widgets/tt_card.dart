import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../services/hydrogen_api.dart';
import 'tt_schedule_modal.dart';

class TTCard extends StatelessWidget {
  final IntegratedStatus? status;

  const TTCard({
    super.key,
    required this.status,
  });

  String _buildTTStatusText() {
    final tt = status?.tt;
    if (tt == null || tt.totalCount == 0) return '-';
    return '${tt.totalCount}대 중 ${tt.currentIndex}번째';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (status?.tt != null) {
          TTScheduleModal.show(context, status!.tt);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'T/T 현황',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.black.withOpacity(0.6),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.black.withOpacity(0.4),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '잔압',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.black.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            status?.ttPressure?.toString() ?? '-',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            ' bar',
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
                Container(
                  width: 1,
                  height: 50,
                  color: AppColors.black.withOpacity(0.1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '사용',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.black.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildTTStatusText(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
