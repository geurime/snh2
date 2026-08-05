import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../constants/spacing.dart';
import '../../../constants/typography.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/pressable.dart';
import '../../../widgets/sheet_header.dart';

/// 제목을 7번 연타하면 열린다. 직원만 쓰는 숨은 진입점.
///
/// 다른 시트 넷과 같은 `SheetHeader`를 써서 형태를 통일한다.
class AdminPasswordModal extends StatefulWidget {
  const AdminPasswordModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (_) => const AdminPasswordModal(),
    );
  }

  @override
  State<AdminPasswordModal> createState() => _AdminPasswordModalState();
}

class _AdminPasswordModalState extends State<AdminPasswordModal> {
  final _controller = TextEditingController();
  bool _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.gray900,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _login() async {
    setState(() => _checking = true);
    final success = await context.read<AdminProvider>().login(_controller.text);
    if (!mounted) return;
    setState(() => _checking = false);

    if (success) {
      Navigator.pop(context);
      _notify('관리자 모드를 켰어요');
    } else {
      _notify('비밀번호가 맞지 않아요');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpace.xl,
          right: AppSpace.xl,
          top: AppSpace.sm,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHeader(
              title: '관리자 모드',
              subtitle: '비밀번호를 입력해 주세요',
            ),
            const SizedBox(height: AppSpace.xxl),
            TextField(
              controller: _controller,
              obscureText: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              autofocus: true,
              onSubmitted: (_) => _login(),
              style: AppText.number.copyWith(
                color: AppColors.gray900,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.lg,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            Pressable(
              onTap: _checking ? null : _login,
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _checking ? AppColors.gray300 : AppColors.orange,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  _checking ? '확인 중' : '확인',
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
