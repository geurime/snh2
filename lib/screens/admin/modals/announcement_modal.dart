import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/spacing.dart';
import '../../../constants/typography.dart';
import '../../../widgets/pressable.dart';
import '../../../widgets/sheet_header.dart';
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
          backgroundColor: AppColors.gray900,
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
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHeader(
              title: '공지사항',
              subtitle: '빈 칸으로 저장하면 공지가 삭제됩니다',
            ),
            const SizedBox(height: AppSpace.xxl),
            TextField(
              controller: _controller,
              maxLines: 3,
              style: AppText.body.copyWith(color: AppColors.gray900),
              decoration: InputDecoration(
                // 힌트를 두지 않는다 — 완결된 한국어 문장은 회색이어도
                // "이미 등록된 공지"로 읽힌다. 이 칸 내용은 손님 화면에 그대로
                // 나가서 오해 비용이 크다. 제목과 부연이 이미 용도를 말한다.
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(AppSpace.lg),
              ),
            ),
            const SizedBox(height: AppSpace.xxl),
            Pressable(
              onTap: _save,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 52),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  '저장',
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.card,
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
