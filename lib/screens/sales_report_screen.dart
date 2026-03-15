import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/colors.dart';
import '../services/hydrogen_api.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final HydrogenApiService _api = HydrogenApiService();

  late int _selectedYear;
  late int _selectedMonth;

  MonthlySalesStats? _monthlyStats;
  List<DailySales>? _weeklyData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 월별 통계 로드
    final stats = await _api.getMonthlySalesStats(_selectedYear, _selectedMonth);

    // 최근 7일 데이터 로드 (오늘 데이터 있으면 오늘까지, 없으면 어제까지)
    final today = DateTime.now();
    final todaySales = await _api.getSales(_formatDate(today));
    final hasTodayData = (todaySales?['totalKg'] ?? 0).toDouble() > 0;
    final endDate = hasTodayData ? today : today.subtract(const Duration(days: 1));
    final startDate = endDate.subtract(const Duration(days: 6));
    final weekly = await _api.getSalesRange(_formatDate(startDate), _formatDate(endDate));

    setState(() {
      _monthlyStats = stats;
      _weeklyData = weekly;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showMonthPicker() {
    int tempYear = _selectedYear;
    int tempMonth = _selectedMonth;

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
                // 드래그 핸들 바
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
                  '월 선택',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 16),
                // 휠 피커
                SizedBox(
                  height: 180,
                  child: Row(
                    children: [
                      // 년도 피커
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: _selectedYear - 2020,
                          ),
                          itemExtent: 36,
                          onSelectedItemChanged: (index) {
                            tempYear = 2020 + index;
                          },
                          children: List.generate(
                            DateTime.now().year - 2020 + 1,
                            (index) => Center(
                              child: Text(
                                '${(2020 + index) % 100}년',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 월 피커
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: _selectedMonth - 1,
                          ),
                          itemExtent: 36,
                          onSelectedItemChanged: (index) {
                            tempMonth = index + 1;
                          },
                          children: List.generate(
                            12,
                            (index) => Center(
                              child: Text(
                                '${index + 1}월',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // 확인 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedYear = tempYear;
                        _selectedMonth = tempMonth;
                      });
                      _loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '매출 추이',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthlySummaryCard(),
                  const SizedBox(height: 20),
                  _buildChartCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthlySummaryCard() {
    final stats = _monthlyStats;
    final totalKg = stats?.totalKg ?? 0;
    final totalVehicles = stats?.totalVehicles ?? 0;
    final dailyAvgKg = stats?.dailyAvgKg ?? 0;
    final dailyAvgVehicles = stats?.dailyAvgVehicles ?? 0;

    return Container(
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
            children: [
              GestureDetector(
                onTap: _showMonthPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_selectedYear % 100}년 $_selectedMonth월',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.chevronDown,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '매출 현황',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: LucideIcons.fuel,
                  label: '총 판매량',
                  value: '${totalKg.toStringAsFixed(0)}kg',
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.black.withOpacity(0.1),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: LucideIcons.car,
                  label: '총 충전대수',
                  value: '$totalVehicles대',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '일평균 ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.black.withOpacity(0.5),
                        ),
                      ),
                      Text(
                        '${dailyAvgKg.toStringAsFixed(0)}kg',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: AppColors.black.withOpacity(0.15),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '일평균 ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.black.withOpacity(0.5),
                        ),
                      ),
                      Text(
                        '${dailyAvgVehicles.toStringAsFixed(0)}대',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 22,
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.black.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard() {
    final data = _weeklyData ?? [];

    // Y축 최대값 계산
    double maxKg = 100;
    for (final d in data) {
      if (d.totalKg > maxKg) {
        maxKg = d.totalKg;
      }
    }
    maxKg = ((maxKg / 100).ceil() * 100).toDouble();
    if (maxKg < 100) maxKg = 100;

    return Container(
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
            children: [
              Icon(
                LucideIcons.barChart3,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '최근 7일 추이',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: data.isEmpty
                ? Center(
                    child: Text(
                      '데이터가 없습니다',
                      style: TextStyle(
                        color: AppColors.black.withOpacity(0.5),
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxKg / 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.black.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: maxKg / 5,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.black.withOpacity(0.4),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < data.length) {
                                final date = DateTime.parse(data[index].date);
                                final dayNames = ['일', '월', '화', '수', '목', '금', '토'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    dayNames[date.weekday % 7],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.black.withOpacity(0.5),
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (data.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxKg,
                      lineBarsData: [
                        LineChartBarData(
                          spots: data.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value.totalKg,
                            );
                          }).toList(),
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withOpacity(0.15),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => AppColors.black,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final d = data[spot.x.toInt()];
                              final date = DateTime.parse(d.date);
                              return LineTooltipItem(
                                '${date.month}/${date.day}\n${d.totalKg.toInt()}kg · ${d.totalVehicles}대',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '판매량 (kg)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.black.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
