import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/spacing.dart';
import '../../constants/strings.dart';
import '../../constants/typography.dart';
import '../../providers/station_provider.dart';
import '../../services/hydrogen_api.dart';
import '../../widgets/state_toggle.dart';
import '../sales_report_screen.dart';
import 'modals/announcement_modal.dart';
import 'modals/sales_input_modal.dart';
import 'modals/tt_today_modal.dart';
import 'widgets/admin_section.dart';
import 'widgets/metric_bar.dart';
import 'widgets/tt_section.dart';

/// 직원 화면. 손님 화면과 목적이 정반대다.
///
/// 손님은 5초 보고 나가니 적게 보여주고 대신 판단해준다.
/// 직원은 하루 종일 쓰니 상태를 다 보여주고 빨리 입력하게 한다.
///
/// 배치 기준은 "안 보면 손해가 큰 순서"다:
/// 이상 지표 → 업무(하루 흐름 순) → T/T → 충전소(손님 화면에 나가는 것들).
class AdminScreen extends StatefulWidget {
  /// 떠 있는 모드 전환 스위치가 가리지 않도록 비워둘 아래 여백.
  final double bottomInset;

  const AdminScreen({super.key, this.bottomInset = 0});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  /// 이 시각 이후로 마감이 비어 있으면 오렌지로 알린다.
  /// 아침부터 재촉하면 오렌지가 배경 소음이 되어 정작 T/T가 안 보인다.
  static const _closingReminderHour = 18;

  final _api = HydrogenApiService();

  bool _isLoading = true;

  ChargerStatus _chargerA = ChargerStatus.operating;
  ChargerStatus _chargerB = ChargerStatus.operating;
  CarWashStatus _carWash = CarWashStatus.operating;
  TTStatus _ttA = TTStatus.empty;
  TTStatus _ttB = TTStatus.empty;
  String? _announcement;

  int _ttTotalCount = 0;
  double? _salesKg;
  int? _salesCount;
  double? _flowMeter;

  /// 서버가 미입력 날짜에도 `totalKg: 0, totalVehicles: 0`을 채워 보낸다.
  /// 값만 보면 "0대 입력함"과 "아직 안 함"이 구분되지 않으므로
  /// DB 레코드 존재 여부(`id`)로 판단한다.
  bool _salesEntered = false;

  MonthlyPressureStats? _pressureStats;
  MonthlyLossStats? _lossStats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];

    final status = await _api.getIntegratedStatus();
    final sales = await _api.getSales(today);
    final pressure = await _api.getMonthlyPressureStats(now.year, now.month);
    final loss = await _api.getMonthlyLossStats(now.year, now.month);

    if (!mounted) return;
    setState(() {
      if (status != null) {
        _chargerA = status.station.chargerA;
        _chargerB = status.station.chargerB;
        _carWash = status.station.carWashStatus;
        _ttA = status.station.ttAStatus;
        _ttB = status.station.ttBStatus;
        _announcement = status.station.announcement;
        _ttTotalCount = status.tt.totalCount;
      }
      _salesEntered = sales?['id'] != null;
      _flowMeter = (sales?['flowMeter'] as num?)?.toDouble();
      _salesKg = (sales?['totalKg'] as num?)?.toDouble();
      _salesCount = (sales?['totalVehicles'] as num?)?.toInt();
      _pressureStats = pressure;
      _lossStats = loss;
      _isLoading = false;
    });

    if (status != null && mounted) {
      context.read<StationProvider>().updateFromApi(status.station);
    }
  }

  // ── 상태 변경 ──
  // 전부 2상태 토글이다. 3상태 순환은 "점검중"에 닿으려면 "고장"을 거쳐야 하고
  // 그 중간값이 서버에 저장되면서 손님 화면에 나간다. 2상태면 한 번 더 눌러 원복된다.

  Future<void> _toggleTT(String name) async {
    final current = name == 'A' ? _ttA : _ttB;
    if (current == TTStatus.inUse) return; // 잔압으로 자동 판정되는 값

    final next = current == TTStatus.empty ? TTStatus.standby : TTStatus.empty;
    final ok = await _api.setTTStatus(
      ttAStatus: name == 'A' ? next : _ttA,
      ttBStatus: name == 'B' ? next : _ttB,
    );
    if (!ok || !mounted) return;

    setState(() {
      if (name == 'A') {
        _ttA = next;
      } else {
        _ttB = next;
      }
    });
  }

  Future<void> _toggleCharger(String name) async {
    final current = name == 'A' ? _chargerA : _chargerB;
    final next = current == ChargerStatus.operating
        ? ChargerStatus.broken
        : ChargerStatus.operating;

    final ok = await _api.updateCharger(
      chargerA: name == 'A' ? next : null,
      chargerB: name == 'B' ? next : null,
    );
    if (!ok || !mounted) return;

    setState(() {
      if (name == 'A') {
        _chargerA = next;
      } else {
        _chargerB = next;
      }
    });

    final station = context.read<StationProvider>();
    if (name == 'A') {
      station.setChargerA(next);
    } else {
      station.setChargerB(next);
    }
  }

  Future<void> _toggleCarWash() async {
    final next = _carWash == CarWashStatus.operating
        ? CarWashStatus.closed
        : CarWashStatus.operating;

    final ok = await _api.updateCarWash(next);
    if (!ok || !mounted) return;

    setState(() => _carWash = next);
    if (mounted) context.read<StationProvider>().setCarWashStatus(next);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.gray100,
        body: Center(child: CircularProgressIndicator(color: AppColors.orange)),
      );
    }

    final closingIsDue = DateTime.now().hour >= _closingReminderHour;

    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.orange,
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpace.xl,
              AppSpace.lg,
              AppSpace.xl,
              AppSpace.xxl + widget.bottomInset,
            ),
            children: [
              const _Header(),
              // 지표는 별도 섹션이 아니라 헤더의 부속 정보다 — 제목에 붙이고
              // 아래를 벌려서 업무 섹션과 갈린다.
              const SizedBox(height: AppSpace.sm),
              MetricBar(pressure: _pressureStats, loss: _lossStats),
              const SizedBox(height: AppSpace.xxl),

              // 하루 흐름 순 — 아침 T/T 입력 → 16시 매출 보고 주문량 판단 → 퇴근 전 마감
              AdminSection(
                label: S.sectionWork,
                children: [
                  AdminRow(
                    label: S.rowTT,
                    value: _ttTotalCount > 0
                        ? S.ttCount(_ttTotalCount)
                        : S.notEntered,
                    isTodo: _ttTotalCount == 0,
                    onTap: () => TTTodayModal.show(
                      context,
                      initialCount: _ttTotalCount,
                      onSave: (count) => setState(() => _ttTotalCount = count),
                    ),
                  ),
                  AdminRow(
                    label: S.rowSalesReport,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SalesReportScreen(),
                      ),
                    ),
                  ),
                  AdminRow(
                    label: S.rowClosing,
                    value: _salesEntered
                        ? S.salesSummary(_salesCount ?? 0, _salesKg ?? 0)
                        : S.notEntered,
                    isTodo: !_salesEntered && closingIsDue,
                    showDivider: false,
                    onTap: () => SalesInputModal.show(
                      context,
                      initialFlowMeter: _flowMeter,
                      initialSalesKg: _salesKg,
                      initialSalesCount: _salesCount,
                      hasRecord: _salesEntered,
                      onSave: (flowMeter, kg, count) => setState(() {
                        _flowMeter = flowMeter;
                        _salesKg = kg;
                        _salesCount = count;
                        _salesEntered = true;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),

              TTSection(ttA: _ttA, ttB: _ttB, onToggle: _toggleTT),
              const SizedBox(height: AppSpace.xl),

              // 여기 값은 전부 손님 화면에 즉시 나간다
              AdminSection(
                label: S.sectionStation,
                children: [
                  _chargerRow(S.rowChargerA, _chargerA, 'A'),
                  _chargerRow(S.rowChargerB, _chargerB, 'B'),
                  AdminRow(
                    label: S.rowCarWash,
                    isAlert: _carWash != CarWashStatus.operating,
                    control: StateToggle(
                      labelA: S.washOpen,
                      labelB: S.washClosed,
                      isB: _carWash != CarWashStatus.operating,
                      onChanged: (_) => _toggleCarWash(),
                    ),
                  ),
                  AdminRow(
                    label: S.rowNotice,
                    showDivider: false,
                    onTap: () => AnnouncementModal.show(
                      context,
                      initialAnnouncement: _announcement,
                      onSave: (a) => setState(() => _announcement = a),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chargerRow(String label, ChargerStatus status, String name) {
    final isDown = status != ChargerStatus.operating;
    return AdminRow(
      label: label,
      isAlert: isDown,
      control: StateToggle(
        labelA: S.chargerOk,
        labelB: S.chargerDown,
        isB: isDown,
        onChanged: (_) => _toggleCharger(name),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      alignment: Alignment.centerLeft,
      child: Text(
        S.adminTitle,
        style: AppText.screenTitle.copyWith(color: AppColors.gray900),
      ),
    );
  }
}
