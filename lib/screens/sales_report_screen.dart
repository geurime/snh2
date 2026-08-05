import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';
import '../constants/typography.dart';
import '../services/analytics.dart';
import '../services/hydrogen_api.dart';
import '../widgets/pressable.dart';

/// 월 통계와 최근 7일 흐름.
///
/// 지금은 쓰는 사람이 확인되지 않은 화면이라 **구조는 건드리지 않는다.**
/// 폐기한 색·스케일 밖 글씨를 토큰으로 맞추고, 정보를 안 주는 아이콘만 뺐다.
/// 개편은 진입 이벤트를 붙여 사용량을 본 뒤에 한다.
///
/// 차트와 리스트는 역할이 다르다 — 차트는 **형태**, 리스트는 **일곱 날을 나란히**.
/// 툴팁은 한 점씩 답하므로 리스트를 대신하지 못한다.
class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  static const _dayNames = ['일', '월', '화', '수', '목', '금', '토'];

  final HydrogenApiService _api = HydrogenApiService();

  late int _selectedYear;
  late int _selectedMonth;

  MonthlySalesStats? _monthlyStats;
  List<DailySales>? _weeklyData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 이 화면을 직원이 실제로 여는지 몰라서 남길지 지울지 못 정하고 있다.
    Analytics.salesReportOpened();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final stats = await _api.getMonthlySalesStats(
      _selectedYear,
      _selectedMonth,
    );

    // 오늘 마감이 끝났으면 오늘까지, 아니면 어제까지.
    // 판정은 값이 아니라 레코드 존재 여부로 한다 — 서버가 미입력 날짜에도
    // totalKg 0을 채워 보내서, 값으로 보면 "진짜 0kg으로 마감한 날"이 빠진다.
    final today = DateTime.now();
    final todaySales = await _api.getSales(_formatDate(today));
    final closedToday = todaySales?['id'] != null;
    final endDate = closedToday
        ? today
        : today.subtract(const Duration(days: 1));
    final weekly = await _api.getSalesRange(
      _formatDate(endDate.subtract(const Duration(days: 6))),
      _formatDate(endDate),
    );

    if (!mounted) return;
    setState(() {
      _monthlyStats = stats;
      _weeklyData = weekly;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
          '매출 추이',
          style: AppText.screenTitle.copyWith(color: AppColors.gray900),
        ),
        actions: [
          // 화면 전체를 지배하는 컨트롤이라 카드 안이 아니라 헤더에 둔다.
          Padding(
            padding: const EdgeInsets.only(right: AppSpace.lg),
            child: _MonthButton(
              year: _selectedYear,
              month: _selectedMonth,
              onTap: _showMonthPicker,
            ),
          ),
        ],
      ),
      // 본문에 SafeArea가 없어 마지막 카드가 내비게이션 바에 가렸다.
      // (시트의 SafeArea와 별개다 — 상단은 AppBar가 처리하므로 하단만)
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            )
          : SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.xl,
                  AppSpace.xs,
                  AppSpace.xl,
                  AppSpace.xxl,
                ),
                children: [
                  _buildSummary(),
                  const SizedBox(height: AppSpace.xl),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpace.xs,
                      bottom: AppSpace.sm,
                    ),
                    child: Text(
                      '최근 7일',
                      style: AppText.tag.copyWith(color: AppColors.gray600),
                    ),
                  ),
                  _buildTrend(),
                ],
              ),
            ),
    );
  }

  /// 총계는 두지 않는다 — 컴퓨터에서 확인되는 값이다.
  /// 앱에서만 알 수 있는 건 평균이라 그것만 남긴다.
  Widget _buildSummary() {
    final stats = _monthlyStats;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.card),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Stat(
                label: '일평균 판매량',
                value: (stats?.dailyAvgKg ?? 0).toStringAsFixed(0),
                unit: 'kg',
              ),
            ),
            const VerticalDivider(
              width: AppSpace.xxl,
              thickness: 1,
              color: AppColors.gray300,
            ),
            Expanded(
              child: _Stat(
                label: '일평균 대수',
                value: (stats?.dailyAvgVehicles ?? 0).toStringAsFixed(0),
                unit: '대',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrend() {
    final data = _weeklyData ?? [];

    if (data.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.card),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Center(
          child: Text(
            '기록이 없어요',
            style: AppText.body.copyWith(color: AppColors.gray600),
          ),
        ),
      );
    }

    // Y축은 최대값을 100단위로 올려 반씩 나눈다 — 574면 0/300/600,
    // 900이면 0/500/1000으로 데이터에 따라 알아서 읽기 좋은 수가 된다.
    var maxKg = 100.0;
    for (final d in data) {
      if (d.totalKg > maxKg) maxKg = d.totalKg;
    }
    maxKg = ((maxKg / 100).ceil() * 100).toDouble();

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
          SizedBox(height: 170, child: _chart(data, maxKg)),
          const SizedBox(height: 18),
          for (final (i, d) in data.reversed.indexed)
            _DayRow(sales: d, showDivider: i < data.length - 1),
        ],
      ),
    );
  }

  Widget _chart(List<DailySales> data, double maxKg) {
    final labelStyle = AppText.label.copyWith(color: AppColors.gray600);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxKg / 2,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.gray300, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxKg / 2,
              reservedSize: 44,
              getTitlesWidget: (value, _) =>
                  Text('${value.toInt()}', style: labelStyle),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                final date = DateTime.parse(data[i].date);
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpace.sm),
                  child: Text(_dayNames[date.weekday % 7], style: labelStyle),
                );
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
            spots: [
              for (var i = 0; i < data.length; i++)
                FlSpot(i.toDouble(), data[i].totalKg),
            ],
            isCurved: false,
            color: AppColors.orangeText,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.orangeText,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(show: true, color: AppColors.orangeTint),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.gray900,
            getTooltipItems: (spots) => spots.map((spot) {
              final d = data[spot.x.toInt()];
              final date = DateTime.parse(d.date);
              return LineTooltipItem(
                '${date.month}/${date.day}\n'
                '${d.totalKg.toInt()}kg · ${d.totalVehicles}대',
                AppText.label.copyWith(
                  color: AppColors.card,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showMonthPicker() {
    var tempYear = _selectedYear;
    var tempMonth = _selectedMonth;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xl,
            AppSpace.sm,
            AppSpace.xl,
            AppSpace.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '월 선택',
                      style: AppText.screenTitle.copyWith(
                        color: AppColors.gray900,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Pressable(
                    scale: 0.88,
                    onTap: () => Navigator.pop(sheetContext),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.centerRight,
                      child: const Icon(
                        LucideIcons.x,
                        size: AppIcon.lg,
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              SizedBox(
                height: 180,
                child: Row(
                  children: [
                    Expanded(
                      child: _Wheel(
                        initial: _selectedYear - 2020,
                        count: DateTime.now().year - 2020 + 1,
                        label: (i) => '${(2020 + i) % 100}년',
                        onChanged: (i) => tempYear = 2020 + i,
                      ),
                    ),
                    Expanded(
                      child: _Wheel(
                        initial: _selectedMonth - 1,
                        count: 12,
                        label: (i) => '${i + 1}월',
                        onChanged: (i) => tempMonth = i + 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              Pressable(
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    _selectedYear = tempYear;
                    _selectedMonth = tempMonth;
                  });
                  _loadData();
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    '확인',
                    style: AppText.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.card,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  final int year;
  final int month;
  final VoidCallback onTap;

  const _MonthButton({
    required this.year,
    required this.month,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.94,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${year % 100}년 $month월',
              style: AppText.body.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            const Icon(
              LucideIcons.chevronDown,
              size: AppIcon.sm,
              color: AppColors.gray600,
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _Stat({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label.copyWith(color: AppColors.gray600)),
        const SizedBox(height: AppSpace.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppText.number.copyWith(color: AppColors.gray900),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: AppText.label.copyWith(
                color: AppColors.gray900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final DailySales sales;
  final bool showDivider;

  const _DayRow({required this.sales, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(sales.date);
    final day = _SalesReportScreenState._dayNames[date.weekday % 7];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.gray100))
            : null,
      ),
      child: Row(
        children: [
          Text(
            '${date.month}/${date.day} $day',
            style: AppText.body.copyWith(
              color: AppColors.gray600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          Text(
            '${sales.totalKg.toInt()}kg · ${sales.totalVehicles}대',
            style: AppText.body.copyWith(
              color: AppColors.gray900,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  final int initial;
  final int count;
  final String Function(int) label;
  final ValueChanged<int> onChanged;

  const _Wheel({
    required this.initial,
    required this.count,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: initial),
      itemExtent: 38,
      onSelectedItemChanged: onChanged,
      children: [
        for (var i = 0; i < count; i++)
          Center(
            child: Text(
              label(i),
              style: AppText.body.copyWith(color: AppColors.gray900),
            ),
          ),
      ],
    );
  }
}
