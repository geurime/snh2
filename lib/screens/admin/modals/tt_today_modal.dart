import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/colors.dart';
import '../../../constants/spacing.dart';
import '../../../constants/typography.dart';
import '../../../widgets/pressable.dart';
import '../../../widgets/sheet_header.dart';
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 입력칸이 하나뿐이라 제목이 곧 질문이고, 스테퍼가 곧 답이다.
            // 별도 필드 라벨('오늘 총 대수')은 제목과 같은 말이라 뺐다.
            const SheetHeader(
              title: '오늘 T/T 몇 대 쓰나요?',
              subtitle: '지금 몇 번째인지는 잔압 변화로 자동 계산돼요',
            ),
            const SizedBox(height: AppSpace.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Pressable(
                  scale: 0.9,
                  onTap: () {
                    if (_tempCount > 0) {
                      setState(() => _tempCount--);
                    }
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.orangeTint,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: const Icon(
                      LucideIcons.minus,
                      color: AppColors.orangeText,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Text(
                  '$_tempCount',
                  style: AppText.display.copyWith(color: AppColors.gray900),
                ),
                const SizedBox(width: 32),
                Pressable(
                  scale: 0.9,
                  onTap: () {
                    setState(() => _tempCount++);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.orangeTint,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: const Icon(
                      LucideIcons.plus,
                      color: AppColors.orangeText,
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
