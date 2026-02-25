import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/colors.dart';

class EntryGuideDialog extends StatefulWidget {
  const EntryGuideDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hideGuide = prefs.getBool('hideEntryGuide') ?? false;
    if (!hideGuide && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const EntryGuideDialog(),
      );
    }
  }

  @override
  State<EntryGuideDialog> createState() => _EntryGuideDialogState();
}

class _EntryGuideDialogState extends State<EntryGuideDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '진입 안내',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '입구의 콘 배치를 확인해주세요',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.black.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildConeImage(
                    'assets/cone_open.jpeg',
                    '입장 가능',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildConeImage(
                    'assets/cone_blocked.jpeg',
                    '입장 불가',
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '콘이 없다면 양쪽 어디든 바로 진입!\n빈 충전기가 있으면 줄 서지 마시고 바로 들어오세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.black.withOpacity(0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _buildDontShowAgainCheckbox(),
            const SizedBox(height: 16),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildConeImage(String asset, String label, Color color) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDontShowAgainCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _dontShowAgain ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _dontShowAgain
                    ? AppColors.primary
                    : AppColors.black.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: _dontShowAgain
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            '다시 보지 않기',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: () async {
        if (_dontShowAgain) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hideEntryGuide', true);
        }
        if (mounted) Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            '확인',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

extension on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }
}
