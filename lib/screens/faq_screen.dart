import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';
import '../constants/typography.dart';

class FaqImage {
  final String path;
  final String label;

  const FaqImage({required this.path, required this.label});
}

class FaqItem {
  final String question;
  final String answer;
  final List<FaqImage>? images;

  const FaqItem({required this.question, required this.answer, this.images});
}

/// 여섯 항목을 다 펼쳐서 보여준다.
///
/// 접는 게 나은 건 질문 목록을 훑어야 할 때인데, 답이 전부 1~3줄이라
/// 펼쳐도 훑기에 방해가 안 된다. 접으면 답이 있는지 보려고 여섯 번 눌러야 한다.
/// 카드 경계가 질문 단위를 갈라주므로 아코디언 없이도 스캔이 된다.
///
/// 검색창도 없앴다 — 여섯 개는 스크롤 한 번이면 다 보인다.
/// 검색은 "다 볼 수 없을 때" 쓰는 도구고, 여기선 입력이라는 일만 하나 늘린다.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _items = [
    FaqItem(
      question: '들어가도 되는지 모르겠어요',
      answer: '입구의 콘 배치를 확인해주세요.\n'
          '콘이 없으면 양쪽 어디든 바로 들어오시면 됩니다.',
      images: [
        FaqImage(path: 'assets/cone_open.jpeg', label: '입장 가능'),
        FaqImage(path: 'assets/cone_blocked.jpeg', label: '입장 불가'),
      ],
    ),
    FaqItem(
      question: '충전은 얼마나 걸리나요?',
      answer: '승용차는 약 5분, 버스는 약 30분 걸려요.',
    ),
    FaqItem(
      question: '몇 %까지 충전되나요?',
      answer: '안전을 위해 최대 95%까지 충전됩니다.\n'
          '수소 공급 상황에 따라 달라질 수 있어요.',
    ),
    FaqItem(
      question: '예약할 수 있나요?',
      answer: '예약은 안 되고 현장 선착순이에요.',
    ),
    FaqItem(
      question: '몇 시까지 방문해야 하나요?',
      answer: '마감 10분 전인 19:50까지 오시는 걸 권해드려요.',
    ),
    FaqItem(
      question: '결제는 어떻게 하나요?',
      answer: '카드, 현금(계좌이체), 성남사랑상품권, E1 포인트로 결제할 수 있어요.\n\n'
          '모바일 결제는 삼성페이(MST)만 되고 애플페이(NFC)는 안 됩니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      appBar: AppBar(
        backgroundColor: AppColors.gray100,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.gray900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '자주 묻는 질문',
          style: AppText.screenTitle.copyWith(color: AppColors.gray900),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xl,
          AppSpace.xs,
          AppSpace.xl,
          AppSpace.xxl,
        ),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpace.md),
        itemBuilder: (_, i) => _Card(item: _items[i]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final FaqItem item;

  const _Card({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.card),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.question,
            style: AppText.body.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            item.answer,
            style: AppText.body.copyWith(
              color: AppColors.gray600,
              height: 1.5,
            ),
          ),
          if (item.images != null) ...[
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                for (final (i, img) in item.images!.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpace.md),
                  Expanded(child: _Photo(image: img)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final FaqImage image;

  const _Photo({required this.image});

  /// 진입 안내 다이얼로그와 같은 규칙 — 막힌 경우에만 색이 붙는다.
  bool get _isBlocked => image.label.contains('불가');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: Image.asset(image.path, fit: BoxFit.cover),
        ),
        const SizedBox(height: AppSpace.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.xs + 2,
          ),
          decoration: BoxDecoration(
            color: _isBlocked ? AppColors.orangeTint : AppColors.gray100,
            borderRadius: BorderRadius.circular(AppSpace.sm),
          ),
          child: Text(
            image.label,
            style: AppText.label.copyWith(
              fontWeight: FontWeight.w700,
              color: _isBlocked ? AppColors.orangeText : AppColors.gray900,
            ),
          ),
        ),
      ],
    );
  }
}
