import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/colors.dart';

class FaqItem {
  final String question;
  final String answer;
  final List<FaqImage>? images;

  const FaqItem({required this.question, required this.answer, this.images});
}

class FaqImage {
  final String path;
  final String label;

  const FaqImage({required this.path, required this.label});
}

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<FaqItem> _allFaqs = const [
    FaqItem(
      question: '들어가도 되는지 모르겠어요',
      answer: '입구의 콘 배치를 확인해주세요.\n콘이 없다면 양쪽 어디든 바로 들어오시면 됩니다!',
      images: [
        FaqImage(path: 'assets/cone_open.jpeg', label: '입장 가능'),
        FaqImage(path: 'assets/cone_blocked.jpeg', label: '입장 불가'),
      ],
    ),
    FaqItem(
      question: '충전은 얼마나 걸리나요?',
      answer: '승용차는 약 5분, 버스는 약 30분 소요됩니다.',
    ),
    FaqItem(
      question: '몇 %까지 충전되나요?',
      answer: '안전을 위해 최대 95%까지 충전됩니다.\n수소 공급 상황에 따라 변동될 수 있습니다.',
    ),
    FaqItem(
      question: '예약할 수 있나요?',
      answer: '예약은 불가하며, 현장 선착순으로 이용하실 수 있습니다.',
    ),
    FaqItem(
      question: '몇 시까지 방문해야 하나요?',
      answer: '영업 마감 10분 전인 19:50 이전 도착을 권장합니다.',
    ),
    FaqItem(
      question: '결제는 어떻게 하나요?',
      answer: '카드, 현금(계좌이체), 성남사랑상품권, E1 포인트로 결제 가능합니다.\n\n모바일 결제는 삼성페이(MST)만 가능하며, 애플페이(NFC)는 지원되지 않습니다.',
    ),
  ];

  List<FaqItem> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _allFaqs;
    return _allFaqs.where((faq) {
      return faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq.answer.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '자주 묻는 질문',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: '질문 검색',
                hintStyle: TextStyle(
                  color: AppColors.black.withOpacity(0.4),
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: AppColors.primary,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          color: AppColors.black.withOpacity(0.4),
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          // FAQ 목록
          Expanded(
            child: _filteredFaqs.isEmpty
                ? Center(
                    child: Text(
                      '검색 결과가 없습니다',
                      style: TextStyle(
                        color: AppColors.black.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    itemCount: _filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = _filteredFaqs[index];
                      return _buildFaqItem(faq);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerText(String answer) {
    final defaultStyle = TextStyle(
      fontSize: 14,
      color: AppColors.black.withOpacity(0.7),
      height: 1.5,
    );
    final brandStyle = TextStyle(
      fontSize: 14,
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
      height: 1.5,
    );

    // 강조할 단어들 색상 적용
    final brandWords = ['삼성페이(MST)', '애플페이(NFC)', '95%', '19:50'];
    final List<TextSpan> spans = [];
    String remaining = answer;

    while (remaining.isNotEmpty) {
      int nearestIndex = remaining.length;
      String? nearestWord;

      for (final word in brandWords) {
        final index = remaining.indexOf(word);
        if (index != -1 && index < nearestIndex) {
          nearestIndex = index;
          nearestWord = word;
        }
      }

      if (nearestWord != null) {
        if (nearestIndex > 0) {
          spans.add(TextSpan(text: remaining.substring(0, nearestIndex), style: defaultStyle));
        }
        spans.add(TextSpan(text: nearestWord, style: brandStyle));
        remaining = remaining.substring(nearestIndex + nearestWord.length);
      } else {
        spans.add(TextSpan(text: remaining, style: defaultStyle));
        remaining = '';
      }
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildFaqItem(FaqItem faq) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: ThemeData().copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            faq.question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.black.withOpacity(0.4),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _buildAnswerText(faq.answer),
            ),
            if (faq.images != null) ...[
              const SizedBox(height: 12),
              Row(
                children: faq.images!.map((img) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            img.path,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: img.label == '입장 가능'
                                ? Colors.green.withOpacity(0.15)
                                : Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            img.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: img.label == '입장 가능'
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
