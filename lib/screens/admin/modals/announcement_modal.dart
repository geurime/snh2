import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../services/hydrogen_api.dart';

class AnnouncementModal extends StatefulWidget {
  final String? initialAnnouncement;
  final Function(String?) onSave;

  const AnnouncementModal({
    super.key,
    this.initialAnnouncement,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialAnnouncement,
    required Function(String?) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AnnouncementModal(
        initialAnnouncement: initialAnnouncement,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AnnouncementModal> createState() => _AnnouncementModalState();
}

class _AnnouncementModalState extends State<AnnouncementModal> {
  late final TextEditingController _controller;
  final _apiService = HydrogenApiService();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAnnouncement);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    final success = await _apiService.updateAnnouncement(
      text.isEmpty ? null : text,
    );

    if (success && mounted) {
      widget.onSave(text.isEmpty ? null : text);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('공지사항이 저장되었습니다'),
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
                '공지사항',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '빈 칸으로 저장하면 공지가 삭제됩니다',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.black.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '공지사항을 입력하세요',
                hintStyle: TextStyle(color: AppColors.black.withOpacity(0.4)),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
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
