import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../services/hydrogen_api.dart';

class MealModal extends StatefulWidget {
  final String? initialLunch;
  final String? initialDinner;
  final Function(String? lunch, String? dinner) onSave;

  const MealModal({
    super.key,
    this.initialLunch,
    this.initialDinner,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialLunch,
    String? initialDinner,
    required Function(String? lunch, String? dinner) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MealModal(
        initialLunch: initialLunch,
        initialDinner: initialDinner,
        onSave: onSave,
      ),
    );
  }

  @override
  State<MealModal> createState() => _MealModalState();
}

class _MealModalState extends State<MealModal> {
  late final TextEditingController _lunchController;
  late final TextEditingController _dinnerController;
  final _apiService = HydrogenApiService();

  @override
  void initState() {
    super.initState();
    _lunchController = TextEditingController(text: widget.initialLunch);
    _dinnerController = TextEditingController(text: widget.initialDinner);
  }

  @override
  void dispose() {
    _lunchController.dispose();
    _dinnerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final lunch = _lunchController.text.trim();
    final dinner = _dinnerController.text.trim();

    final success = await _apiService.updateMeal(
      lunch: lunch.isEmpty ? null : lunch,
      dinner: dinner.isEmpty ? null : dinner,
    );

    if (success && mounted) {
      widget.onSave(
        lunch.isEmpty ? null : lunch,
        dinner.isEmpty ? null : dinner,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('식사 메뉴가 저장되었습니다'),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
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
            Center(
              child: Text(
                '오늘의 식사',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '점심 메뉴',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lunchController,
              decoration: InputDecoration(
                hintText: '점심 메뉴를 입력하세요',
                hintStyle: TextStyle(color: AppColors.black.withOpacity(0.4)),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '저녁 메뉴',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dinnerController,
              decoration: InputDecoration(
                hintText: '저녁 메뉴를 입력하세요',
                hintStyle: TextStyle(color: AppColors.black.withOpacity(0.4)),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
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
