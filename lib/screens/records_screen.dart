import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/colors.dart';
import '../services/hydrogen_api.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final HydrogenApiService _apiService = HydrogenApiService();

  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;
  bool _isLoadingData = false;
  WorklogData? _selectedWorklog;
  TTScheduleData? _selectedTTSchedule;
  Map<String, dynamic>? _selectedSales;
  Map<String, dynamic>? _prevDaySales;


  // 직원 이름
  static const String _staff1 = '김강풍';
  static const String _staff2 = '이원흥';

  // 근무 스케줄 수정 데이터 (날짜별)
  final Map<String, Map<String, String>> _staffOverrides = {};

  // 기본 스케줄 계산
  Map<String, String> _getDefaultStaffSchedule(DateTime date) {
    final weekday = date.weekday; // 1=월, 7=일

    switch (weekday) {
      case 7: // 일: 김강풍 풀
        return {'type': 'full', 'full': _staff1};
      case 1: // 월: 김강풍 오전, 이원흥 오후
        return {'type': 'split', 'am': _staff1, 'pm': _staff2};
      case 2: // 화: 김강풍 풀
        return {'type': 'full', 'full': _staff1};
      case 3: // 수: 이원흥 오전, 김강풍 오후
        return {'type': 'split', 'am': _staff2, 'pm': _staff1};
      case 4: // 목: 이원흥 풀
        return {'type': 'full', 'full': _staff2};
      case 5: // 금: 번갈아가며 (2/6 기준 이원흥 오전, 김강풍 오후)
        final reference = DateTime(2026, 2, 6);
        final daysDiff = date.difference(reference).inDays;
        final weeksDiff = (daysDiff / 7).floor();
        if (weeksDiff % 2 == 0) {
          return {'type': 'split', 'am': _staff2, 'pm': _staff1};
        } else {
          return {'type': 'split', 'am': _staff1, 'pm': _staff2};
        }
      case 6: // 토: 이원흥 풀
        return {'type': 'full', 'full': _staff2};
      default:
        return {'type': 'full', 'full': _staff1};
    }
  }

  Map<String, String> _getStaffSchedule(String dateKey, DateTime date) {
    if (_staffOverrides.containsKey(dateKey)) {
      return _staffOverrides[dateKey]!;
    }
    return _getDefaultStaffSchedule(date);
  }


  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadDateData();
  }

  Future<void> _loadDateData() async {
    if (_selectedDate == null) return;

    setState(() => _isLoadingData = true);

    final dateKey = _formatDate(_selectedDate!);
    final prevDate = _selectedDate!.subtract(const Duration(days: 1));
    final prevDateKey = _formatDate(prevDate);

    final results = await Future.wait([
      _apiService.getWorklog(dateKey),
      _apiService.getTTScheduleByDate(dateKey),
      _apiService.getSales(dateKey),
      _apiService.getSales(prevDateKey),
    ]);

    if (mounted) {
      setState(() {
        _selectedWorklog = results[0] as WorklogData?;
        _selectedTTSchedule = results[1] as TTScheduleData?;
        _selectedSales = results[2] as Map<String, dynamic>?;
        _prevDaySales = results[3] as Map<String, dynamic>?;
        _isLoadingData = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      LucideIcons.arrowLeft,
                      color: AppColors.black,
                      size: 24,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showSearchModal(),
                        child: Icon(
                          LucideIcons.search,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentMonth = DateTime.now();
                            _selectedDate = DateTime.now();
                          });
                          _loadDateData();
                        },
                        child: Text(
                          '오늘',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 월 네비게이션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.chevronLeft,
                        size: 20,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  Text(
                    '${_currentMonth.year}년 ${_currentMonth.month}월',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.chevronRight,
                        size: 20,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 요일 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
                  final isWeekend = day == '일' || day == '토';
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isWeekend
                              ? (day == '일' ? const Color(0xFFE57373) : AppColors.primary)
                              : AppColors.black.withOpacity(0.5),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // 달력 그리드
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildCalendarGrid(),
            ),

            const SizedBox(height: 20),

            // 선택된 날짜의 기록
            Expanded(
              child: _buildSelectedDateRecords(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 일요일 = 0
    final daysInMonth = lastDayOfMonth.day;

    final today = DateTime.now();
    final totalCells = ((firstWeekday + daysInMonth) / 7).ceil() * 7;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate((totalCells / 7).ceil(), (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final cellIndex = weekIndex * 7 + dayIndex;
              final dayNumber = cellIndex - firstWeekday + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return Expanded(child: SizedBox(height: 44));
              }

              final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
              final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
              final isSelected = _selectedDate != null &&
                  date.year == _selectedDate!.year &&
                  date.month == _selectedDate!.month &&
                  date.day == _selectedDate!.day;
              final isSunday = dayIndex == 0;

              // 날짜 색상 결정
              Color dateColor;
              if (isSelected) {
                dateColor = AppColors.card;
              } else if (isToday) {
                dateColor = AppColors.primary;
              } else if (isSunday) {
                dateColor = const Color(0xFFE57373);
              } else {
                dateColor = AppColors.black;
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    _loadDateData();
                  },
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isToday
                              ? AppColors.primary.withOpacity(0.15)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: dateColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedDateRecords() {
    if (_selectedDate == null) {
      return const SizedBox.shrink();
    }

    final dateKey = _formatDate(_selectedDate!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_selectedDate!.month}월 ${_selectedDate!.day}일',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingData
                ? ListView(
                    children: [
                      _buildCardSkeleton(),
                      const SizedBox(height: 12),
                      _buildCardSkeleton(),
                      const SizedBox(height: 12),
                      _buildCardSkeleton(),
                      const SizedBox(height: 12),
                      _buildCardSkeleton(),
                    ],
                  )
                : ListView(
                    children: [
                      // 근무자 (항상 표시)
                      GestureDetector(
                        onTap: () => _showStaffEditModal(dateKey, _selectedDate!),
                        child: _buildStaffCard(_getStaffSchedule(dateKey, _selectedDate!)),
                      ),
                      const SizedBox(height: 12),
                      // T/T 입고 카드
                      _buildTTRecordCard(),
                      const SizedBox(height: 12),
                      // 매출 카드
                      _buildSalesCard(),
                      const SizedBox(height: 12),
                      // 특이사항 카드
                      _buildWorklogCard(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Map<String, String> schedule) {
    final isFull = schedule['type'] == 'full';
    String content;
    String detail;

    if (isFull) {
      content = schedule['full']!;
      detail = '풀근무';
    } else {
      content = '${schedule['am']} · ${schedule['pm']}';
      detail = '오전 · 오후';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.user,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '근무자',
                  style: TextStyle(
                    fontSize: 13,
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
          Text(
            detail,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesCard() {
    double kg = double.tryParse(_selectedSales?['totalKg']?.toString() ?? '') ?? 0.0;
    int count = int.tryParse(_selectedSales?['totalVehicles']?.toString() ?? '') ?? 0;
    final hasData = kg > 0 || count > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasData
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.black.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.barChart,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '매출',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.black.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasData ? '${kg.toStringAsFixed(0)}kg · ${count}대' : '기록 없음',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: hasData
                        ? AppColors.black
                        : AppColors.black.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTTRecordCard() {
    final dateKey = _formatDate(_selectedDate!);

    // 예정 시간 (전날 주문한 시간)
    List<String> ttList = _selectedTTSchedule?.schedules ?? [];

    final hasData = ttList.isNotEmpty;
    final timesText = ttList.join(' · ');

    return GestureDetector(
      onTap: () => _showTTScheduleEditModal(dateKey, ttList),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasData
                ? AppColors.primary.withOpacity(0.5)
                : AppColors.black.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.truck,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'T/T 입고',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.black.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasData ? timesText : '기록 없음',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasData
                          ? AppColors.black
                          : AppColors.black.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            if (hasData)
              Text(
                '${ttList.length}대',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.black.withOpacity(0.6),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.black.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorklogCard() {
    final hasNotes = _selectedWorklog?.notes?.isNotEmpty ?? false;
    final notes = _selectedWorklog?.notes ?? '기록 없음';

    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasNotes
                ? AppColors.primary.withOpacity(0.5)
                : AppColors.black.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.clipboardList,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '특이사항',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.black.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notes,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasNotes
                          ? AppColors.black
                          : AppColors.black.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  void _showStaffEditModal(String dateKey, DateTime date) {
    final currentSchedule = _getStaffSchedule(dateKey, date);
    String selectedType = currentSchedule['type']!;
    String selectedFull = currentSchedule['full'] ?? _staff1;
    String selectedAm = currentSchedule['am'] ?? _staff1;
    String selectedPm = currentSchedule['pm'] ?? _staff2;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                    Text(
                      '근무자 수정',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 근무 타입 선택
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedType = 'full';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selectedType == 'full'
                                    ? AppColors.primary
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '풀근무',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: selectedType == 'full'
                                        ? Colors.white
                                        : AppColors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedType = 'split';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selectedType == 'split'
                                    ? AppColors.primary
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '교대',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: selectedType == 'split'
                                        ? Colors.white
                                        : AppColors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (selectedType == 'full') ...[
                      Text(
                        '근무자',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStaffSelectButton(
                            _staff1,
                            selectedFull == _staff1,
                            () => setModalState(() => selectedFull = _staff1),
                          ),
                          const SizedBox(width: 12),
                          _buildStaffSelectButton(
                            _staff2,
                            selectedFull == _staff2,
                            () => setModalState(() => selectedFull = _staff2),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        '오전 (07:30~12:00)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStaffSelectButton(
                            _staff1,
                            selectedAm == _staff1,
                            () => setModalState(() => selectedAm = _staff1),
                          ),
                          const SizedBox(width: 12),
                          _buildStaffSelectButton(
                            _staff2,
                            selectedAm == _staff2,
                            () => setModalState(() => selectedAm = _staff2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '오후 (12:00~20:00)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStaffSelectButton(
                            _staff1,
                            selectedPm == _staff1,
                            () => setModalState(() => selectedPm = _staff1),
                          ),
                          const SizedBox(width: 12),
                          _buildStaffSelectButton(
                            _staff2,
                            selectedPm == _staff2,
                            () => setModalState(() => selectedPm = _staff2),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    // 버튼들
                    Row(
                      children: [
                        // 기본값으로 되돌리기
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _staffOverrides.remove(dateKey);
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '기본값',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 저장
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (selectedType == 'full') {
                                  _staffOverrides[dateKey] = {
                                    'type': 'full',
                                    'full': selectedFull,
                                  };
                                } else {
                                  _staffOverrides[dateKey] = {
                                    'type': 'split',
                                    'am': selectedAm,
                                    'pm': selectedPm,
                                  };
                                }
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStaffSelectButton(String name, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonBox({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.black.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.black.withOpacity(0.08),
        highlightColor: AppColors.black.withOpacity(0.02),
        child: Row(
          children: [
            _buildSkeletonBox(width: 44, height: 44, borderRadius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSkeletonBox(width: 50, height: 13),
                  const SizedBox(height: 6),
                  _buildSkeletonBox(width: 100, height: 18),
                ],
              ),
            ),
            _buildSkeletonBox(width: 60, height: 13),
          ],
        ),
      ),
    );
  }

  void _showSearchModal() {
    final searchController = TextEditingController();
    List<NotesSearchResult> searchResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
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
                      Text(
                        '특이사항 검색',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '최근 1년 내 특이사항을 검색합니다',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.black.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: '검색어 입력',
                                hintStyle: TextStyle(
                                  color: AppColors.black.withOpacity(0.4),
                                ),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                prefixIcon: Icon(
                                  LucideIcons.search,
                                  color: AppColors.black.withOpacity(0.4),
                                  size: 20,
                                ),
                              ),
                              onSubmitted: (value) async {
                                if (value.trim().isEmpty) return;
                                setModalState(() => isSearching = true);
                                final results = await _apiService.searchNotes(value.trim());
                                setModalState(() {
                                  searchResults = results;
                                  isSearching = false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () async {
                              final value = searchController.text;
                              if (value.trim().isEmpty) return;
                              setModalState(() => isSearching = true);
                              final results = await _apiService.searchNotes(value.trim());
                              setModalState(() {
                                searchResults = results;
                                isSearching = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.search,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: isSearching
                            ? const Center(child: CircularProgressIndicator())
                            : searchResults.isEmpty
                                ? Center(
                                    child: Text(
                                      searchController.text.isEmpty
                                          ? '검색어를 입력하세요'
                                          : '검색 결과가 없습니다',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.black.withOpacity(0.4),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    itemCount: searchResults.length,
                                    itemBuilder: (context, index) {
                                      final result = searchResults[index];
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);
                                          // 해당 날짜로 이동
                                          final parts = result.date.split('-');
                                          if (parts.length == 3) {
                                            final date = DateTime(
                                              int.parse(parts[0]),
                                              int.parse(parts[1]),
                                              int.parse(parts[2]),
                                            );
                                            setState(() {
                                              _currentMonth = DateTime(date.year, date.month);
                                              _selectedDate = date;
                                            });
                                            _loadDateData();
                                          }
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          child: IntrinsicHeight(
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Container(
                                                  width: 4,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary,
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        _formatSearchDate(result.date),
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppColors.primary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        result.notes,
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          color: AppColors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatSearchDate(String date) {
    final parts = date.split('-');
    if (parts.length == 3) {
      return '${parts[0]}년 ${int.parse(parts[1])}월 ${int.parse(parts[2])}일';
    }
    return date;
  }

  void _showTTScheduleEditModal(String dateKey, List<String> currentSchedules) {
    List<String> schedules = List.from(currentSchedules);
    final timeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    Text(
                      'T/T 입고 시간 수정',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 시간 추가
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: timeController,
                            decoration: InputDecoration(
                              hintText: '시간 입력 (예: 09:00)',
                              hintStyle: TextStyle(
                                color: AppColors.black.withOpacity(0.4),
                              ),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            final time = timeController.text.trim();
                            if (time.isNotEmpty) {
                              setModalState(() {
                                schedules.add(time);
                                schedules.sort();
                              });
                              timeController.clear();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.plus,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 현재 시간 목록
                    if (schedules.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            '등록된 시간이 없습니다',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.black.withOpacity(0.4),
                            ),
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: schedules.asMap().entries.map((entry) {
                          final index = entry.key;
                          final time = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      schedules.removeAt(index);
                                    });
                                  },
                                  child: Icon(
                                    LucideIcons.x,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () async {
                        final success = await _apiService.updateTTScheduleByDate(
                          dateKey,
                          schedules,
                        );
                        if (success) {
                          Navigator.pop(context);
                          _loadDateData();
                        }
                      },
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
          },
        );
      },
    );
  }
}
