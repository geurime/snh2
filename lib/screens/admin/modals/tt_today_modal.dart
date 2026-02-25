import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/colors.dart';
import '../../../services/hydrogen_api.dart';

class TTTodayModal extends StatefulWidget {
  final int initialCount;
  final Function(int count) onSave;

  const TTTodayModal({
    super.key,
    required this.initialCount,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required int initialCount,
    required Function(int count) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TTTodayModal(
        initialCount: initialCount,
        onSave: onSave,
      ),
    );
  }

  @override
  State<TTTodayModal> createState() => _TTTodayModalState();
}

class _TTTodayModalState extends State<TTTodayModal> {
  late int _tempCount;
  final _apiService = HydrogenApiService();

  @override
  void initState() {
    super.initState();
    _tempCount = widget.initialCount;
  }

  Future<void> _save() async {
    final success = await _apiService.updateTTStatus(totalCount: _tempCount);

    if (success && mounted) {
      widget.onSave(_tempCount);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오늘 T/T가 $_tempCount대로 설정되었습니다'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '오늘 T/T 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '이후 잔압 변화로 자동 계산됩니다',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.black.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '오늘 총 대수',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.black.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if (_tempCount > 0) {
                      setState(() => _tempCount--);
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.minus,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Text(
                  '$_tempCount',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(width: 32),
                GestureDetector(
                  onTap: () {
                    setState(() => _tempCount++);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.plus,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    '저장',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
