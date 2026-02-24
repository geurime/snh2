import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../widgets/banner_slider.dart';
import '../services/hydrogen_api.dart';
import 'faq_screen.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final HydrogenApiService _apiService = HydrogenApiService();
  final TextEditingController _suggestionController = TextEditingController();

  @override
  void dispose() {
    _suggestionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '안내',
                style: TextStyle(
                  fontFamily: 'Badasseugi',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 24),

              // 운영 정보
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(LucideIcons.clock, '영업시간', '07:30~20:00 (연중무휴)'),
                    const SizedBox(height: 12),
                    _buildInfoRow(LucideIcons.mapPin, '주소', '경기도 성남시 중원구 갈현동 546-7', onTap: () {
                      _showMapModal(context);
                    }),
                    const SizedBox(height: 12),
                    _buildInfoRow(LucideIcons.phone, '전화번호 (성남에너지)', '031-755-7600', onTap: () {
                      launchUrl(Uri.parse('tel:031-755-7600'));
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 이용 정보
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(LucideIcons.creditCard, '충전 요금', '11,000원/kg'),
                    const SizedBox(height: 12),
                    _buildInfoRow(LucideIcons.fuel, '충전기', '2기 운영 (A 승용우선 · B 버스우선)'),
                    const SizedBox(height: 12),
                    _buildInfoRow(LucideIcons.gift, '혜택', '세차 할인권 지급 · E1 포인트카드 발행'),
                    const SizedBox(height: 12),
                    _buildInfoRow(LucideIcons.landmark, '계좌번호', '농협 351-1199-9916-73', onTap: () {
                      Clipboard.setData(const ClipboardData(text: '351-1199-9916-73'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('계좌번호가 복사되었습니다'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.black,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 건의사항 · 자주 묻는 질문
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickButton(
                        icon: LucideIcons.messageSquare,
                        label: '건의사항',
                        onTap: () => _showSuggestionModal(context),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: AppColors.black.withOpacity(0.1),
                    ),
                    Expanded(
                      child: _buildQuickButton(
                        icon: LucideIcons.helpCircle,
                        label: '자주 묻는 질문',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FaqScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 슬라이드 배너
              const BannerSlider(),
              const SizedBox(height: 24),

              // 개인정보 처리방침
              Center(
                child: GestureDetector(
                  onTap: () {
                    launchUrl(
                      Uri.parse('https://snh2-production.up.railway.app/privacy-policy.html'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  child: Text(
                    '개인정보 처리방침',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.black.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String content, {VoidCallback? onTap}) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.black.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.black.withOpacity(0.4),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: row,
      );
    }
    return row;
  }

  void _showMapModal(BuildContext context) {
    const address = '경기도 성남시 중원구 갈현동 546-7';
    const lat = 37.421716;
    const lng = 127.155140;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                  '길찾기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 20),
                _buildMapOption(
                  context,
                  'assets/map_icons/kakaomap.png',
                  '카카오맵',
                  () async {
                    final kakaoUrl = 'kakaomap://look?p=$lat,$lng';
                    final kakaoWebUrl = 'https://map.kakao.com/link/map/성남수소충전소,$lat,$lng';
                    if (await canLaunchUrl(Uri.parse(kakaoUrl))) {
                      await launchUrl(Uri.parse(kakaoUrl));
                    } else {
                      await launchUrl(Uri.parse(kakaoWebUrl), mode: LaunchMode.externalApplication);
                    }
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                _buildMapOption(
                  context,
                  'assets/map_icons/navermap.webp',
                  '네이버지도',
                  () async {
                    final naverUrl = Uri.parse('nmap://place?lat=$lat&lng=$lng&name=${Uri.encodeComponent(address)}&appname=com.geurime.snh2');
                    final webUrl = Uri.parse('https://map.naver.com/v5/search/${Uri.encodeComponent(address)}');
                    if (await canLaunchUrl(naverUrl)) {
                      await launchUrl(naverUrl);
                    } else {
                      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                    }
                    Navigator.pop(context);
                  },
                ),
                if (Platform.isIOS) ...[
                  const SizedBox(height: 12),
                  _buildMapOption(
                    context,
                    'assets/map_icons/applemap.png',
                    'Apple 지도',
                    () async {
                      final appleUrl = Uri.parse('https://maps.apple.com/?q=${Uri.encodeComponent(address)}&ll=$lat,$lng');
                      await launchUrl(appleUrl, mode: LaunchMode.externalApplication);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapOption(BuildContext context, String? iconPath, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (iconPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  iconPath,
                  width: 36,
                  height: 36,
                ),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF03C75A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'N',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: AppColors.black.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuggestionModal(BuildContext context) {
    _suggestionController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                '건의사항',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '개선점이나 의견을 남겨주세요',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _suggestionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '내용을 입력해주세요',
                  hintStyle: TextStyle(
                    color: AppColors.black.withOpacity(0.4),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final content = _suggestionController.text.trim();
                    if (content.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('내용을 입력해주세요'),
                          backgroundColor: AppColors.black,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final success = await _apiService.submitSuggestion(content);
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? '건의사항이 전송되었습니다' : '전송에 실패했습니다'),
                        backgroundColor: AppColors.black,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '전송',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }
}
