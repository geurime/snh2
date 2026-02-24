import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openEonjewaStore(),
      child: Container(
        width: double.infinity,
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFA7C3E2).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/eonjewa_logo.png',
              height: 50,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '언제와?',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Konkon',
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '이제 물어볼 필요없어요',
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Konkon',
                      color: AppColors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEonjewaStore() async {
    final Uri url;
    if (Platform.isIOS) {
      url = Uri.parse('https://apps.apple.com/kr/app/id6758357292');
    } else {
      url = Uri.parse('https://play.google.com/store/apps/details?id=com.geurime.eonjewa');
    }

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
