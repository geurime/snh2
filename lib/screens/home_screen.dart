import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/colors.dart';
import '../providers/station_provider.dart';
import '../providers/admin_provider.dart';
import '../services/hydrogen_api.dart';
import '../widgets/banner_slider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  Timer? _apiTimer;

  // API 데이터
  final HydrogenApiService _apiService = HydrogenApiService();
  IntegratedStatus? _status;
  bool _isLoading = true;

  // 안내 배너
  bool _showInfoBanner = false;

  // 관리자 모드 진입용
  int _adminTapCount = 0;
  Timer? _adminTapTimer;

  // 마감 팝업 표시 여부
  bool _closedPopupShown = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _startApiTimer();
    _checkEntryGuidePopup();
  }

  /// 진입 안내 팝업 표시 여부 확인
  Future<void> _checkEntryGuidePopup() async {
    final prefs = await SharedPreferences.getInstance();
    final hideGuide = prefs.getBool('hideEntryGuide') ?? false;
    if (!hideGuide && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEntryGuidePopup();
      });
    }
  }

  /// API 데이터 새로고침 (15초마다)
  void _startApiTimer() {
    _apiTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchStatus();
    });
  }

  /// 충전소 상태 조회
  Future<void> _fetchStatus() async {
    final status = await _apiService.getIntegratedStatus();
    if (mounted) {
      setState(() {
        // API 성공 시에만 데이터 업데이트 (실패 시 기존 데이터 유지)
        if (status != null) {
          _status = status;
        }
        _isLoading = false;
      });
      if (status != null) {
        context.read<StationProvider>().updateFromApi(status.station);
        // 마감 팝업 (영업중이 아닐 때)
        if (!_closedPopupShown && !status.isOperating) {
          _closedPopupShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showClosedPopup();
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _apiTimer?.cancel();
    _adminTapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '성남수소충전소',
                      style: TextStyle(
                        fontFamily: 'Badasseugi',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    _buildOperationBadge(),
                  ],
                ),
                const SizedBox(height: 16),

                // 마지막 T/T 안내 배너 (마지막 T/T 사용 중일 때만 표시)
                if (_status != null &&
                    _status!.tt.totalCount > 0 &&
                    _status!.tt.currentIndex == _status!.tt.totalCount) ...[
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.info,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '마지막 T/T 운영 중 · 잔압 55bar 이하 시 영업 종료',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 공지사항
                if (context.watch<StationProvider>().announcement != null &&
                    context.watch<StationProvider>().announcement!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '공지',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.watch<StationProvider>().announcement!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 대기 현황 카드
                if (_isLoading)
                  _buildStatusCardSkeleton()
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '충전소 현황',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.black.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildWaitingRow(
                                    '승용',
                                    _status?.waitingCars,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildWaitingRow(
                                    '버스',
                                    _status?.waitingBuses,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 60,
                              color: AppColors.black.withOpacity(0.1),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '예상 대기',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.black.withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() => _showInfoBanner = true);
                                          Future.delayed(const Duration(seconds: 3), () {
                                            if (mounted) {
                                              setState(() => _showInfoBanner = false);
                                            }
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 1),
                                          child: Icon(
                                            LucideIcons.info,
                                            size: 15,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        _calculateWaitTime(),
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        '분',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // 충전기 + 세차장 상태
                if (_isLoading)
                  _buildChargerCardSkeleton()
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildChargerStatus(
                                'B',
                                context.watch<StationProvider>().chargerB,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 80,
                              color: AppColors.black.withOpacity(0.1),
                            ),
                            Expanded(
                              child: _buildChargerStatus(
                                'A',
                                context.watch<StationProvider>().chargerA,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '세차장',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.black.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildCarWashBadge(),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // T/T 현황 카드
                if (_isLoading)
                  _buildTTCardSkeleton()
                else
                  GestureDetector(
                    onTap: () => _showTTScheduleModal(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'T/T 현황',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.black.withOpacity(0.6),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppColors.black.withOpacity(0.4),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      '잔압',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.black.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          _status?.ttPressure?.toString() ?? '-',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Text(
                                          ' bar',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: AppColors.black.withOpacity(0.1),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      '사용',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.black.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _buildTTStatusText(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // 슬라이드 배너
                const BannerSlider(),
              ],
            ),
          ),
        ),

          // 안내 배너
          if (_showInfoBanner)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: _showInfoBanner ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.info, size: 16, color: AppColors.card),
                      const SizedBox(width: 8),
                      Text(
                        '참고용 정보입니다',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.card,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCarWashBadge() {
    final status = context.watch<StationProvider>().carWashStatus;
    Color dotColor;
    String label;

    switch (status) {
      case CarWashStatus.operating:
        dotColor = const Color(0xFF4CAF50);
        label = '운영중';
        break;
      case CarWashStatus.maintenance:
        dotColor = const Color(0xFFFFA726);
        label = '점검중';
        break;
      case CarWashStatus.closed:
        dotColor = const Color(0xFFE57373);
        label = '운영종료';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _buildTTStatusText() {
    final tt = _status?.tt;
    if (tt == null || tt.totalCount == 0) return '-';
    return '${tt.totalCount}대 중 ${tt.currentIndex}번째';
  }

  void _showTTScheduleModal(BuildContext context) {
    final schedules = _status?.tt.schedules ?? [];
    final currentIndex = _status?.tt.currentIndex ?? 0;

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
                  '오늘의 T/T 입고 일정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 20),
                if (schedules.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        '등록된 일정이 없습니다',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.black.withOpacity(0.6),
                        ),
                      ),
                    ),
                  )
                else
                  ...schedules.asMap().entries.map((entry) {
                    final index = entry.key;
                    final time = entry.value;
                    final isCompleted = index < currentIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTTScheduleItem(
                        '${index + 1}차',
                        time,
                        isCompleted,
                      ),
                    );
                  }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTTScheduleItem(String label, String time, bool isCompleted) {
    final color = isCompleted ? Colors.green : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? color.withOpacity(0.1) : Colors.transparent,
        border: isCompleted ? null : Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.schedule,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const Spacer(),
          Text(
            time,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isCompleted ? '완료' : '예정',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargerStatus(String name, ChargerStatus status) {
    final isOperating = status == ChargerStatus.operating;
    Color color;
    IconData icon;

    switch (status) {
      case ChargerStatus.operating:
        color = const Color(0xFF4CAF50);
        icon = LucideIcons.fuel;
        break;
      case ChargerStatus.broken:
        color = const Color(0xFFE57373);
        icon = LucideIcons.ban;
        break;
      case ChargerStatus.maintenance:
        color = const Color(0xFFFFA726);
        icon = LucideIcons.wrench;
        break;
    }

    return Column(
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          status.displayName,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Badasseugi',
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 운영 상태 뱃지
  Widget _buildOperationBadge() {
    final isOperating = _status?.isOperating ?? false;
    final statusText = _status?.operationStatus ?? '확인중';

    Color dotColor;
    if (_isLoading) {
      dotColor = Colors.grey;
    } else if (isOperating) {
      dotColor = Colors.green;
    } else {
      dotColor = Colors.red;
    }

    return GestureDetector(
      onTap: _handleAdminTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isLoading ? '확인중' : statusText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAdminTap() {
    _adminTapTimer?.cancel();
    _adminTapCount++;

    if (_adminTapCount >= 7) {
      _adminTapCount = 0;
      _showAdminPasswordModal();
    } else {
      _adminTapTimer = Timer(const Duration(seconds: 2), () {
        _adminTapCount = 0;
      });
    }
  }

  void _showAdminPasswordModal() {
    final passwordController = TextEditingController();

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
                  '관리자 모드',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '비밀번호를 입력하세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.black.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: TextStyle(color: AppColors.black.withOpacity(0.3)),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final success = await context.read<AdminProvider>().login(passwordController.text);
                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('관리자 모드가 활성화되었습니다'),
                          backgroundColor: AppColors.black,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('비밀번호가 일치하지 않습니다'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
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
                        '확인',
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

  /// 대기 차량 행 (승용/버스)
  Widget _buildWaitingRow(String label, int? count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.black.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          count?.toString() ?? '-',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          '대',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }

  /// 예상 대기 시간 (서버에서 계산된 값 사용)
  String _calculateWaitTime() {
    final waitMinutes = _status?.estimatedWaitMinutes;
    if (waitMinutes == null) return '-';
    return waitMinutes.toString();
  }

  /// 스켈레톤 박스
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

  /// 스켈레톤 카드 - 충전소 현황
  Widget _buildStatusCardSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.black.withOpacity(0.08),
        highlightColor: AppColors.black.withOpacity(0.02),
        child: Column(
          children: [
            _buildSkeletonBox(width: 80, height: 17),
            const SizedBox(height: 16),
            SizedBox(
              height: 64,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSkeletonBox(width: 56, height: 17),
                        const SizedBox(height: 4),
                        _buildSkeletonBox(width: 60, height: 38),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: AppColors.black.withOpacity(0.1),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSkeletonBox(width: 56, height: 17),
                        const SizedBox(height: 4),
                        _buildSkeletonBox(width: 60, height: 38),
                      ],
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

  /// 스켈레톤 카드 - 충전기 상태
  Widget _buildChargerCardSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.black.withOpacity(0.08),
        highlightColor: AppColors.black.withOpacity(0.02),
        child: Column(
          children: [
            SizedBox(
              height: 106,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSkeletonBox(width: 56, height: 17),
                        const SizedBox(height: 8),
                        _buildSkeletonBox(width: 48, height: 48, borderRadius: 12),
                        const SizedBox(height: 8),
                        _buildSkeletonBox(width: 44, height: 19),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 80,
                    color: AppColors.black.withOpacity(0.1),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSkeletonBox(width: 56, height: 17),
                        const SizedBox(height: 8),
                        _buildSkeletonBox(width: 48, height: 48, borderRadius: 12),
                        const SizedBox(height: 8),
                        _buildSkeletonBox(width: 44, height: 19),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSkeletonBox(width: 100, height: 16),
          ],
        ),
      ),
    );
  }

  /// 스켈레톤 카드 - T/T 현황
  Widget _buildTTCardSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.black.withOpacity(0.08),
        highlightColor: AppColors.black.withOpacity(0.02),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSkeletonBox(width: 56, height: 17),
                _buildSkeletonBox(width: 18, height: 18),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSkeletonBox(width: 28, height: 17),
                        const SizedBox(height: 4),
                        _buildSkeletonBox(width: 60, height: 29),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: AppColors.black.withOpacity(0.1),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSkeletonBox(width: 28, height: 17),
                        const SizedBox(height: 4),
                        _buildSkeletonBox(width: 100, height: 22),
                      ],
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

  /// 진입 안내 팝업
  void _showEntryGuidePopup() {
    bool dontShowAgain = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '진입 안내',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '입구의 콘 배치를 확인해주세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.black.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/cone_open.jpeg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '입장 가능',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/cone_blocked.jpeg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '입장 불가',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '콘이 없다면 양쪽 어디든 바로 진입!\n빈 충전기가 있으면 줄 서지 마시고 바로 들어오세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.black.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          dontShowAgain = !dontShowAgain;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: dontShowAgain ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: dontShowAgain ? AppColors.primary : AppColors.black.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: dontShowAgain
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '다시 보지 않기',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.black.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        if (dontShowAgain) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('hideEntryGuide', true);
                        }
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            '확인',
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

  /// 영업 마감 팝업
  void _showClosedPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: Color(0xFFE53935),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '금일 영업 종료',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '운영시간',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.black.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '07:30~20:00',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '확인',
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
