import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/station_provider.dart';
import '../../services/hydrogen_api.dart';
import '../records_screen.dart';
import '../sales_report_screen.dart';

import 'widgets/admin_header.dart';
import 'widgets/quick_button.dart';
import 'widgets/tt_status_section.dart';
import 'widgets/station_status_section.dart';
import 'widgets/meal_display.dart';
import 'modals/meal_modal.dart';
import 'modals/announcement_modal.dart';
import 'modals/notes_modal.dart';
import 'modals/sales_input_modal.dart';
import 'modals/tt_input_modal.dart';
import 'modals/tt_today_modal.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final HydrogenApiService _apiService = HydrogenApiService();

  bool _isLoading = true;

  ChargerStatus _chargerA = ChargerStatus.operating;
  ChargerStatus _chargerB = ChargerStatus.operating;
  CarWashStatus _carWashStatus = CarWashStatus.operating;
  TTStatus _ttAStatus = TTStatus.empty;
  TTStatus _ttBStatus = TTStatus.empty;
  String? _announcement;

  List<String> _todaySchedules = [];
  int _ttTotalCount = 0;
  List<String> _tomorrowSchedules = [];

  String? _lunchMenu;
  String? _dinnerMenu;

  double? _salesKg;
  int? _salesCount;
  double? _flowMeter;

  MonthlyPressureStats? _pressureStats;
  MonthlyLossStats? _lossStats;
  String? _todayNotes;

  int _titleTapCount = 0;
  DateTime? _lastTapTime;

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

    final now = DateTime.now();
    final pressureStats =
        await _apiService.getMonthlyPressureStats(now.year, now.month);
    final lossStats =
        await _apiService.getMonthlyLossStats(now.year, now.month);

    if (status != null && mounted) {
      setState(() {
        _chargerA = status.station.chargerA;
        _chargerB = status.station.chargerB;
        _carWashStatus = status.station.carWashStatus;
        _ttAStatus = status.station.ttAStatus;
        _ttBStatus = status.station.ttBStatus;
        _announcement = status.station.announcement;

        _todaySchedules = List.from(status.tt.schedules);
        _ttTotalCount = status.tt.totalCount;
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

  void _onTitleTap() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 2) {
      _titleTapCount = 0;
    }
    _lastTapTime = now;
    _titleTapCount++;

    if (_titleTapCount >= 3) {
      _titleTapCount = 0;
      _showSuggestionsPassword();
    }
  }

  void _showSuggestionsPassword() {
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
                    hintStyle:
                        TextStyle(color: AppColors.black.withOpacity(0.4)),
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
                      final success = await context.read<AdminProvider>().login(passwordController.text);
                      if (!context.mounted) return;
                      if (success) {
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
                          final s = suggestions[index];
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
                                  s.content,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${s.createdAt.year}.${s.createdAt.month.toString().padLeft(2, '0')}.${s.createdAt.day.toString().padLeft(2, '0')}',
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

  Future<void> _toggleTTStatus(String name) async {
    TTStatus currentStatus = name == 'A' ? _ttAStatus : _ttBStatus;
    TTStatus newStatus;

    if (currentStatus == TTStatus.empty) {
      newStatus = TTStatus.standby;
    } else if (currentStatus == TTStatus.standby) {
      newStatus = TTStatus.empty;
    } else {
      return;
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
                      AdminHeader(onTitleTap: _onTitleTap),
                      const SizedBox(height: 24),
                      TTStatusSection(
                        pressureStats: _pressureStats,
                        lossStats: _lossStats,
                        ttAStatus: _ttAStatus,
                        ttBStatus: _ttBStatus,
                        onToggleTT: _toggleTTStatus,
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActionsCard(),
                      const SizedBox(height: 12),
                      _buildNavigationCard(),
                      const SizedBox(height: 12),
                      StationStatusSection(
                        chargerA: _chargerA,
                        chargerB: _chargerB,
                        carWashStatus: _carWashStatus,
                        onChargerATap: () async {
                          final newStatus = _nextChargerStatus(_chargerA);
                          final success =
                              await _apiService.updateCharger(chargerA: newStatus);
                          if (success) {
                            setState(() => _chargerA = newStatus);
                            context.read<StationProvider>().setChargerA(newStatus);
                          }
                        },
                        onChargerBTap: () async {
                          final newStatus = _nextChargerStatus(_chargerB);
                          final success =
                              await _apiService.updateCharger(chargerB: newStatus);
                          if (success) {
                            setState(() => _chargerB = newStatus);
                            context.read<StationProvider>().setChargerB(newStatus);
                          }
                        },
                        onCarWashTap: () async {
                          final newStatus = _nextCarWashStatus(_carWashStatus);
                          final success = await _apiService.updateCarWash(newStatus);
                          if (success) {
                            setState(() => _carWashStatus = newStatus);
                            context.read<StationProvider>().setCarWashStatus(newStatus);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: QuickButton(
                  icon: LucideIcons.gauge,
                  label: 'T/T 설정',
                  onTap: () => TTTodayModal.show(
                    context,
                    initialCount: _ttTotalCount,
                    onSave: (count) => setState(() => _ttTotalCount = count),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.black.withOpacity(0.1),
              ),
              Expanded(
                child: QuickButton(
                  icon: LucideIcons.truck,
                  label: 'T/T 일정',
                  onTap: () => TTInputModal.show(
                    context,
                    todaySchedules: _todaySchedules,
                    tomorrowSchedules: _tomorrowSchedules,
                    onSave: (today, tomorrow) {
                      setState(() {
                        _todaySchedules = today;
                        _tomorrowSchedules = tomorrow;
                      });
                    },
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.black.withOpacity(0.1),
              ),
              Expanded(
                child: QuickButton(
                  icon: LucideIcons.barChart,
                  label: '마감 입력',
                  onTap: () => SalesInputModal.show(
                    context,
                    initialFlowMeter: _flowMeter,
                    initialSalesKg: _salesKg,
                    initialSalesCount: _salesCount,
                    onSave: (flowMeter, salesKg, salesCount) {
                      setState(() {
                        _flowMeter = flowMeter;
                        _salesKg = salesKg;
                        _salesCount = salesCount;
                      });
                    },
                  ),
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
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => MealModal.show(
                    context,
                    initialLunch: _lunchMenu,
                    initialDinner: _dinnerMenu,
                    onSave: (lunch, dinner) {
                      setState(() {
                        _lunchMenu = lunch;
                        _dinnerMenu = dinner;
                      });
                    },
                  ),
                  child: (_lunchMenu == null && _dinnerMenu == null)
                      ? QuickButton(
                          icon: LucideIcons.utensils,
                          label: '식사 입력',
                          onTap: () => MealModal.show(
                            context,
                            initialLunch: _lunchMenu,
                            initialDinner: _dinnerMenu,
                            onSave: (lunch, dinner) {
                              setState(() {
                                _lunchMenu = lunch;
                                _dinnerMenu = dinner;
                              });
                            },
                          ),
                        )
                      : MealDisplay(
                          lunchMenu: _lunchMenu,
                          dinnerMenu: _dinnerMenu,
                        ),
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.black.withOpacity(0.1),
              ),
              Expanded(
                child: QuickButton(
                  icon: LucideIcons.megaphone,
                  label: '공지',
                  onTap: () => AnnouncementModal.show(
                    context,
                    initialAnnouncement: _announcement,
                    onSave: (announcement) {
                      setState(() => _announcement = announcement);
                    },
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.black.withOpacity(0.1),
              ),
              Expanded(
                child: QuickButton(
                  icon: LucideIcons.clipboardList,
                  label: '특이사항',
                  onTap: () => NotesModal.show(
                    context,
                    initialNotes: _todayNotes,
                    onSave: (notes) {
                      setState(() => _todayNotes = notes);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard() {
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
            child: QuickButton(
              icon: LucideIcons.pieChart,
              label: '매출 추이',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SalesReportScreen(),
                  ),
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
            child: QuickButton(
              icon: LucideIcons.calendar,
              label: '운영일지',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecordsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
