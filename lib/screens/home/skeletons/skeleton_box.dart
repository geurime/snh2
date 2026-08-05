import 'package:flutter/material.dart';
import '../../../constants/colors.dart';

/// 데이터가 오기 전 자리를 잡아두는 흰 상자.
///
/// 반짝이지 않는다 — 15초 폴링이라 로딩이 짧고, 움직이면 오히려 늦어 보인다.
///
/// 크기는 토큰이 아니라 **들어올 글자의 실측치**다. 자리가 안 맞으면
/// 데이터가 도착할 때 화면이 튄다. 그래서 호출부가 매번 직접 적는다.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
