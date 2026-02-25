import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../services/hydrogen_api.dart';

class TTScheduleModal extends StatelessWidget {
  final TTData tt;

  const TTScheduleModal({
    super.key,
    required this.tt,
  });

  static void show(BuildContext context, TTData tt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TTScheduleModal(tt: tt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedules = tt.schedules;
    final currentIndex = tt.currentIndex;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '오늘의 T/T 입고 일정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 20),
            if (schedules.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '등록된 일정이 없습니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.black.withOpacity(0.6),
                    ),
                  ),
                ),
              )
            else
              ...schedules.asMap().entries.map((entry) {
                final index = entry.key;
                final time = entry.value;
                final isCompleted = index < currentIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TTScheduleItem(
                    label: '${index + 1}차',
                    time: time,
                    isCompleted: isCompleted,
                  ),
                );
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TTScheduleItem extends StatelessWidget {
  final String label;
  final String time;
  final bool isCompleted;

  const _TTScheduleItem({
    required this.label,
    required this.time,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? Colors.green : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? color.withOpacity(0.1) : Colors.transparent,
        border: isCompleted ? null : Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.schedule,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const Spacer(),
          Text(
            time,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isCompleted ? '완료' : '예정',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
