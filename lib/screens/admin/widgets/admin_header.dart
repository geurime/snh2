import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../providers/admin_provider.dart';

class AdminHeader extends StatelessWidget {
  final VoidCallback onTitleTap;

  const AdminHeader({
    super.key,
    required this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onTitleTap,
          child: Text(
            '관리',
            style: TextStyle(
              fontFamily: 'Badasseugi',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            context.read<AdminProvider>().logout();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('관리자 모드가 해제되었습니다'),
                backgroundColor: AppColors.black,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.logOut,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '로그아웃',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
