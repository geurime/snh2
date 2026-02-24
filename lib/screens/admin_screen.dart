import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/station_provider.dart';
import '../providers/admin_provider.dart';
import '../services/hydrogen_api.dart';
import 'records_screen.dart';
import 'sales_report_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final HydrogenApiService _apiService = HydrogenApiService();

  bool _isLoading = true;

  // 백엔드 연동 상태
  ChargerStatus _chargerA = ChargerStatus.operating;
  ChargerStatus _chargerB = ChargerStatus.operating;
  CarWashStatus _carWashStatus = CarWashStatus.operating;
  TTStatus _ttAStatus = TTStatus.empty;
  TTStatus _ttBStatus = TTStatus.empty;
  String? _announcement;

  List<String> _ttSchedules = [];  // 오늘 T/T
  int _ttTotalCount = 0;
  int _ttCurrentIndex = 0;
  List<String> _tomorrowSchedules = [];  // 내일 T/T 일정

  String? _lunchMenu;
  String? _dinnerMenu;

  double? _salesKg;
  int? _salesCount;
  double? _flowMeter;

  MonthlyPressureStats? _pressureStats;
  MonthlyLossStats? _lossStats;
  String? _todayNotes;

  // 숨겨진 건의사항 접근용
  int _titleTapCount = 0;
  DateTime? _lastTapTime;

  final TextEditingController _ttTimeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _flowMeterController = TextEditingController();
  final TextEditingController _salesKgController = TextEditingController();
  final TextEditingController _salesCountController = TextEditingController();
  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _lunchController = TextEditingController();
  final TextEditingController _dinnerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final status = await _apiService.getIntegratedStatus();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final sales = await _apiService.getSales(today);
    final worklog = await _apiService.getWorklog(today);

    // 월별 통계
    final now = DateTime.now();
    final pressureStats = await _apiService.getMonthlyPressureStats(now.year, now.month);
    final lossStats = await _apiService.getMonthlyLossStats(now.year, now.month);

    if (status != null && mounted) {
      setState(() {
        _chargerA = status.station.chargerA;
        _chargerB = status.station.chargerB;
        _carWashStatus = status.station.carWashStatus;
        _ttAStatus = status.station.ttAStatus;
        _ttBStatus = status.station.ttBStatus;
        _announcement = status.station.announcement;

        _ttSchedules = List.from(status.tt.schedules);
        _ttTotalCount = status.tt.totalCount;
        _ttCurrentIndex = status.tt.currentIndex;
        _tomorrowSchedules = List.from(status.tomorrowTT.schedules);

        _lunchMenu = status.meal.lunch;
        _dinnerMenu = status.meal.dinner;

        _flowMeter = sales?['flowMeter']?.toDouble();
        _salesKg = sales?['totalKg']?.toDouble();
        _salesCount = sales?['totalVehicles'];

        _pressureStats = pressureStats;
        _lossStats = lossStats;
        _todayNotes = worklog?.notes;

        _isLoading = false;
      });
      context.read<StationProvider>().updateFromApi(status.station);
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _onTitleTap,
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
                      ),
                      const SizedBox(height: 24),

                      // T/T 현황
                      _buildTTStatusSection(),
                      const SizedBox(height: 12),

                      // T/T · 매출 입력 카드
                      // T/T 설정/일정/마감 + 식사/공지/특이사항 통합 카드
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            // 첫 번째 줄: T/T 설정 / T/T 일정 / 마감 입력
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickButton(
                                    icon: LucideIcons.gauge,
                                    label: 'T/T 설정',
                                    onTap: () => _showTodayTTModal(),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: AppColors.black.withOpacity(0.1),
                                ),
                                Expanded(
                                  child: _buildQuickButton(
                                    icon: LucideIcons.truck,
                                    label: 'T/T 일정',
                                    onTap: () => _showTTInputModal(),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: AppColors.black.withOpacity(0.1),
                                ),
                                Expanded(
                                  child: _buildQuickButton(
                                    icon: LucideIcons.barChart,
                                    label: '마감 입력',
                                    onTap: () => _showSalesInputModal(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 1,
                              color: AppColors.black.withOpacity(0.1),
                            ),
                            const SizedBox(height: 16),
                            // 두 번째 줄: 식사 / 공지 / 특이사항
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _showMealModal(context),
                                    child: (_lunchMenu == null && _dinnerMenu == null)
                                        ? _buildQuickButton(
                                            icon: LucideIcons.utensils,
                                            label: '식사 입력',
                                            onTap: () => _showMealModal(context),
                                          )
                                        : Column(
                                            children: [
                                              if (_lunchMenu != null)
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary.withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Text(
                                                        '점심',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppColors.primary,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        _lunchMenu!,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w500,
                                                          color: AppColors.black,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (_lunchMenu != null && _dinnerMenu != null)
                                                const SizedBox(height: 6),
                                              if (_dinnerMenu != null)
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary.withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Text(
                                                        '저녁',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppColors.primary,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        _dinnerMenu!,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w500,
                                                          color: AppColors.black,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: AppColors.black.withOpacity(0.1),
                                ),
                                Expanded(
                                  child: _buildQuickButton(
                                    icon: LucideIcons.megaphone,
                                    label: '공지',
                                    onTap: () => _showAnnouncementModal(),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: AppColors.black.withOpacity(0.1),
                                ),
                                Expanded(
                                  child: _buildQuickButton(
                                    icon: LucideIcons.clipboardList,
                                    label: '특이사항',
                                    onTap: () => _showNotesModal(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 매출 추이 · 운영일지 카드
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
                                icon: LucideIcons.pieChart,
                                label: '매출 추이',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const SalesReportScreen()),
                                  );
                                },
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 60,
                              color: AppColors.black.withOpacity(0.1),
                            ),
                            Expanded(
                              child: _buildQuickButton(
                                icon: LucideIcons.calendar,
                                label: '운영일지',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const RecordsScreen()),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 충전기 · 세차장 상태
                      _buildStationStatusSection(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTTStatusSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '평균 잔압',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.black.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pressureStats != null && _pressureStats!.recordCount > 0
                          ? '${_pressureStats!.averagePressure.toStringAsFixed(2)}bar'
                          : '-',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.black.withOpacity(0.1),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '평균 손실률',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.black.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lossStats != null && _lossStats!.recordCount > 0
                          ? '${_lossStats!.averageLossRate}%'
                          : '-',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTTStatusItem('B', _ttBStatus,
                _ttBStatus == TTStatus.inUse ? null : () => _toggleTTStatus('B'),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildTTStatusItem('A', _ttAStatus,
                _ttAStatus == TTStatus.inUse ? null : () => _toggleTTStatus('A'),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTTStatusItem(String name, TTStatus status, VoidCallback? onTap) {
    Color color;
    String label;

    switch (status) {
      case TTStatus.empty:
        color = AppColors.black.withOpacity(0.3);
        label = '빈통';
        break;
      case TTStatus.standby:
        color = const Color(0xFF4CAF50);
        label = '대기';
        break;
      case TTStatus.inUse:
        color = AppColors.primary;
        label = '사용 중';
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              'T/T $name',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.black.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// T/T 상태 토글 (빈통 ↔ 대기)
  Future<void> _toggleTTStatus(String name) async {
    TTStatus currentStatus;
    TTStatus newStatus;

    if (name == 'A') {
      currentStatus = _ttAStatus;
    } else {
      currentStatus = _ttBStatus;
    }

    // 빈통 ↔ 대기 토글
    if (currentStatus == TTStatus.empty) {
      newStatus = TTStatus.standby;
    } else if (currentStatus == TTStatus.standby) {
      newStatus = TTStatus.empty;
    } else {
      return; // 사용중이면 변경 안 함
    }

    final success = await _apiService.setTTStatus(
      ttAStatus: name == 'A' ? newStatus : _ttAStatus,
      ttBStatus: name == 'B' ? newStatus : _ttBStatus,
    );

    if (success) {
      setState(() {
        if (name == 'A') {
          _ttAStatus = newStatus;
        } else {
          _ttBStatus = newStatus;
        }
      });
    }
  }

  void _showTTIncomingModal() {
    // 입고 가능한 T/T 확인 (빈통만)
    final canIncomingA = _ttAStatus == TTStatus.empty;
    final canIncomingB = _ttBStatus == TTStatus.empty;

    if (!canIncomingA && !canIncomingB) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('입고할 수 있는 빈통이 없습니다'),
          backgroundColor: AppColors.black,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
                  'T/T 입고',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '입고할 T/T를 선택하세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.black.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (canIncomingB)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _performTTIncoming('B'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.container,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'T/T B 입고',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (canIncomingA && canIncomingB) const SizedBox(width: 12),
                    if (canIncomingA)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _performTTIncoming('A'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.container,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'T/T A 입고',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
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
  }

  Future<void> _performTTIncoming(String target) async {
    Navigator.pop(context);

    final result = await _apiService.ttIncoming(target);
    if (result != null) {
      if (result.success) {
        setState(() {
          _ttAStatus = result.ttAStatus;
          _ttBStatus = result.ttBStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('T/T $target 입고 완료'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? '입고에 실패했습니다'),
            backgroundColor: AppColors.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showTTChangeModal() {
    // 교체 가능한지 확인 (사용 중인 T/T와 대기 중인 T/T가 있어야 함)
    final hasInUse = _ttAStatus == TTStatus.inUse || _ttBStatus == TTStatus.inUse;
    final hasStandby = _ttAStatus == TTStatus.standby || _ttBStatus == TTStatus.standby;

    if (!hasInUse || !hasStandby) {
      String message;
      if (!hasInUse && !hasStandby) {
        message = '사용 중인 T/T와 대기 중인 T/T가 없습니다';
      } else if (!hasInUse) {
        message = '사용 중인 T/T가 없습니다';
      } else {
        message = '대기 중인 T/T가 없습니다';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.black,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 교체 방향 결정 (사용 중 → 대기)
    final direction = _ttAStatus == TTStatus.inUse ? 'A>B' : 'B>A';
    final pressureController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
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
                    'T/T 교체',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        direction == 'A>B' ? 'A' : 'B',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          LucideIcons.chevronRight,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        direction == 'A>B' ? 'B' : 'A',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '교체 전 잔압 (나가는 T/T)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pressureController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '예: 55',
                    hintStyle: TextStyle(
                      color: AppColors.black.withOpacity(0.4),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixText: 'bar',
                    suffixStyle: TextStyle(
                      color: AppColors.black.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    final pressure = int.tryParse(pressureController.text);
                    if (pressure == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('잔압을 입력해주세요'),
                          backgroundColor: AppColors.black,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    final result = await _apiService.ttChange(direction, pressure);
                    if (result != null) {
                      if (result.success) {
                        setState(() {
                          _ttAStatus = result.ttAStatus;
                          _ttBStatus = result.ttBStatus;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('T/T 교체 완료 ($direction)'),
                            backgroundColor: const Color(0xFF4CAF50),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.message ?? '교체에 실패했습니다'),
                            backgroundColor: AppColors.black,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
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
                        '교체',
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
  }

  Widget _buildStationStatusSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildChargerButton('A', _chargerA, () async {
              final newStatus = _nextChargerStatus(_chargerA);
              final success =
                  await _apiService.updateCharger(chargerA: newStatus);
              if (success) {
                setState(() => _chargerA = newStatus);
                context.read<StationProvider>().setChargerA(newStatus);
              }
            }),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.black.withOpacity(0.1),
          ),
          Expanded(
            child: _buildChargerButton('B', _chargerB, () async {
              final newStatus = _nextChargerStatus(_chargerB);
              final success =
                  await _apiService.updateCharger(chargerB: newStatus);
              if (success) {
                setState(() => _chargerB = newStatus);
                context.read<StationProvider>().setChargerB(newStatus);
              }
            }),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.black.withOpacity(0.1),
          ),
          Expanded(
            child: _buildCarWashButton(),
          ),
        ],
      ),
    );
  }

  ChargerStatus _nextChargerStatus(ChargerStatus current) {
    switch (current) {
      case ChargerStatus.operating:
        return ChargerStatus.broken;
      case ChargerStatus.broken:
        return ChargerStatus.maintenance;
      case ChargerStatus.maintenance:
        return ChargerStatus.operating;
    }
  }

  CarWashStatus _nextCarWashStatus(CarWashStatus current) {
    switch (current) {
      case CarWashStatus.operating:
        return CarWashStatus.maintenance;
      case CarWashStatus.maintenance:
        return CarWashStatus.closed;
      case CarWashStatus.closed:
        return CarWashStatus.operating;
    }
  }

  Widget _buildCarWashButton() {
    Color color;
    IconData icon;
    String label;

    switch (_carWashStatus) {
      case CarWashStatus.operating:
        color = Colors.green;
        icon = LucideIcons.car;
        label = '운영중';
        break;
      case CarWashStatus.maintenance:
        color = const Color(0xFFFFA726);
        icon = LucideIcons.wrench;
        label = '점검중';
        break;
      case CarWashStatus.closed:
        color = const Color(0xFFE57373);
        icon = LucideIcons.ban;
        label = '운영종료';
        break;
    }

    return GestureDetector(
      onTap: () async {
        final newStatus = _nextCarWashStatus(_carWashStatus);
        final success = await _apiService.updateCarWash(newStatus);
        if (success) {
          setState(() => _carWashStatus = newStatus);
          context.read<StationProvider>().setCarWashStatus(newStatus);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '세차장',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.black.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Badasseugi',
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection() {
    return GestureDetector(
      onTap: () => _showMealModal(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.utensils,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '오늘의 식사',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.black.withOpacity(0.4),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '점심',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.black.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _lunchMenu?.isNotEmpty == true ? _lunchMenu! : '미정',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _lunchMenu?.isNotEmpty == true
                              ? AppColors.black
                              : AppColors.black.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.black.withOpacity(0.1),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '저녁',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.black.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dinnerMenu?.isNotEmpty == true ? _dinnerMenu! : '미정',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _dinnerMenu?.isNotEmpty == true
                                ? AppColors.black
                                : AppColors.black.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargerButton(
      String name, ChargerStatus status, VoidCallback onTap) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case ChargerStatus.operating:
        color = Colors.green;
        icon = LucideIcons.fuel;
        label = '정상';
        break;
      case ChargerStatus.broken:
        color = const Color(0xFFE57373);
        icon = LucideIcons.ban;
        label = '고장';
        break;
      case ChargerStatus.maintenance:
        color = const Color(0xFFFFA726);
        icon = LucideIcons.wrench;
        label = '점검중';
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '충전기 $name',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.black.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Badasseugi',
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
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
                icon,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.black.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: AppColors.black.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _onTitleTap() {
    final now = DateTime.now();

    // 2초 내에 탭해야 카운트
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 2) {
      _titleTapCount = 0;
    }

    _lastTapTime = now;
    _titleTapCount++;

    if (_titleTapCount >= 3) {
      _titleTapCount = 0;
      _showPasswordModal();
    }
  }

  void _showPasswordModal() {
    final passwordController = TextEditingController();

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
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '암호 입력',
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
                  onPressed: () {
                    if (passwordController.text == '011399') {
                      Navigator.pop(context);
                      _showSuggestionsModal();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('암호가 틀렸습니다'),
                          backgroundColor: AppColors.black,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '확인',
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

  void _showSuggestionsModal() async {
    final suggestions = await _apiService.getSuggestions();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
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
                '건의사항 목록',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: suggestions == null || suggestions.isEmpty
                    ? Center(
                        child: Text(
                          '건의사항이 없습니다',
                          style: TextStyle(
                            color: AppColors.black.withOpacity(0.5),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: suggestions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final suggestion = suggestions[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  suggestion.content,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${suggestion.createdAt.year}.${suggestion.createdAt.month.toString().padLeft(2, '0')}.${suggestion.createdAt.day.toString().padLeft(2, '0')} ${suggestion.createdAt.hour.toString().padLeft(2, '0')}:${suggestion.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.black.withOpacity(0.4),
                                  ),
                                ),
                              ],
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

  void _showTodayTTModal() {
    int tempCount = _ttTotalCount;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
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
                      '오늘 T/T 설정',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '이후 잔압 변화로 자동 계산됩니다',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.black.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 총 대수
                    Text(
                      '오늘 총 대수',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.black.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (tempCount > 0) {
                              setModalState(() => tempCount--);
                            }
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              LucideIcons.minus,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        Text(
                          '$tempCount',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(width: 32),
                        GestureDetector(
                          onTap: () {
                            setModalState(() => tempCount++);
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              LucideIcons.plus,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () async {
                        final success = await _apiService.updateTTStatus(
                          totalCount: tempCount,
                        );
                        if (success) {
                          setState(() {
                            _ttTotalCount = tempCount;
                          });
                        }
                        Navigator.pop(context);
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

  void _showTTInputModal() {
    List<String> tempSchedules = List.from(_tomorrowSchedules);

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
                      '내일 T/T 일정 입력',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 내일 일정 목록
                    ...tempSchedules.asMap().entries.map((entry) {
                      final index = entry.key;
                      final time = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${index + 1}차',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.black,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    tempSchedules.removeAt(index);
                                  });
                                },
                                child: Icon(
                                  LucideIcons.x,
                                  size: 18,
                                  color: AppColors.black.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    // 새 일정 추가
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ttTimeController,
                            decoration: InputDecoration(
                              hintText: '예: 0900,1300,1700',
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
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            if (_ttTimeController.text.isNotEmpty) {
                              setModalState(() {
                                final input = _ttTimeController.text;
                                final times = input
                                    .split(',')
                                    .map((t) => t.trim())
                                    .where((t) => t.isNotEmpty);
                                for (var time in times) {
                                  if (time.length == 4 &&
                                      int.tryParse(time) != null) {
                                    time =
                                        '${time.substring(0, 2)}:${time.substring(2)}';
                                  }
                                  tempSchedules.add(time);
                                }
                                _ttTimeController.clear();
                              });
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
                    GestureDetector(
                      onTap: () async {
                        final success =
                            await _apiService.updateTTSchedule(tempSchedules);
                        if (success) {
                          setState(() {
                            _tomorrowSchedules = tempSchedules;
                          });
                        }
                        Navigator.pop(context);
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

  void _showSalesInputModal() {
    _flowMeterController.text = _flowMeter != null && _flowMeter! > 0 ? _flowMeter!.toStringAsFixed(0) : '';
    _salesKgController.text = _salesKg != null && _salesKg! > 0 ? _salesKg!.toStringAsFixed(0) : '';
    _salesCountController.text = _salesCount != null && _salesCount! > 0 ? _salesCount.toString() : '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
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
                  '마감 입력',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '마감 유량계',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _flowMeterController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '예: 123456',
                    hintStyle: TextStyle(
                      color: AppColors.black.withOpacity(0.4),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '판매량',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _salesKgController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '예: 300',
                    hintStyle: TextStyle(
                      color: AppColors.black.withOpacity(0.4),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '충전 대수',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _salesCountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '예: 100',
                    hintStyle: TextStyle(
                      color: AppColors.black.withOpacity(0.4),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixText: '대',
                    suffixStyle: TextStyle(
                      color: AppColors.black.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    final flowMeter = double.tryParse(_flowMeterController.text);
                    final kg = double.tryParse(_salesKgController.text) ?? 0;
                    final count =
                        int.tryParse(_salesCountController.text) ?? 0;
                    final today = DateTime.now().toIso8601String().split('T')[0];

                    final success = await _apiService.updateSales(today, kg, count, flowMeter: flowMeter);
                    if (success) {
                      setState(() {
                        _flowMeter = flowMeter;
                        _salesKg = kg;
                        _salesCount = count;
                      });
                    }
                    Navigator.pop(context);
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
  }

  void _showAnnouncementModal() {
    _announcementController.text = _announcement ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
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
                  '공지사항 수정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '홈 화면에 표시될 공지사항을 입력하세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.black.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _announcementController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '예: 1/25(토) 오후 2시~4시 정기점검 예정',
                    hintStyle: TextStyle(
                      color: AppColors.black.withOpacity(0.4),
                    ),
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
                  onTap: () async {
                    final text = _announcementController.text.isEmpty
                        ? null
                        : _announcementController.text;
                    final success = await _apiService.updateAnnouncement(text);
                    if (success) {
                      setState(() => _announcement = text);
                      context.read<StationProvider>().setAnnouncement(text);
                    }
                    Navigator.pop(context);
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
  }

  void _showMealModal(BuildContext context) {
    _lunchController.text = _lunchMenu ?? '';
    _dinnerController.text = _dinnerMenu ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
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
                  '오늘의 식사',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '점심',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _lunchController,
                  decoration: InputDecoration(
                    hintText: '예: 제육덮밥',
                    hintStyle: TextStyle(
                      color: AppColors.black.withOpacity(0.4),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '저녁',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _dinnerController,
                  decoration: InputDecoration(
                    hintText: '예: 떡만둣국',
                    hintStyle: TextStyle(
                      color: AppColors.black.withOpacity(0.4),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    final lunch = _lunchController.text.isEmpty
                        ? null
                        : _lunchController.text;
                    final dinner = _dinnerController.text.isEmpty
                        ? null
                        : _dinnerController.text;

                    final success = await _apiService.updateMeal(
                      lunch: lunch,
                      dinner: dinner,
                    );
                    if (success) {
                      setState(() {
                        _lunchMenu = lunch;
                        _dinnerMenu = dinner;
                      });
                    }
                    Navigator.pop(context);
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
  }

  void _showNotesModal() {
    _notesController.text = _todayNotes ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
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
                  '오늘의 특이사항',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: '오늘의 특이사항을 입력하세요',
                    hintStyle: TextStyle(
                      color: AppColors.black.withOpacity(0.4),
                    ),
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
                  onTap: () async {
                    final today = DateTime.now().toIso8601String().split('T')[0];
                    final notes = _notesController.text.isEmpty
                        ? null
                        : _notesController.text;
                    final success = await _apiService.updateWorklogNotes(today, notes);
                    if (success) {
                      setState(() => _todayNotes = notes);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('특이사항이 저장되었습니다'),
                          backgroundColor: AppColors.black,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    Navigator.pop(context);
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
  }
}
