import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/spacing.dart';
import '../../constants/strings.dart';
import '../../constants/typography.dart';
import '../../providers/station_provider.dart';
import '../../services/hydrogen_api.dart';
import 'dialogs/admin_password_modal.dart';
import 'dialogs/closed_dialog.dart';
import 'dialogs/entry_guide_dialog.dart';
import 'skeletons/home_skeleton.dart';
import 'widgets/alert_banner.dart';
import 'widgets/load_failed_card.dart';
import 'widgets/station_info.dart';
import 'widgets/stock_card.dart';
import 'widgets/wait_card.dart';
import '../../widgets/pressable.dart';

/// 손님 화면. 이 한 장이 전부다.
///
/// 앱을 깐 사람은 이미 여기 오는 사람이라, 충전소를 찾는 정보가 아니라
/// "지금 갈까 이따 갈까"를 정하는 정보만 둔다.
class HomeScreen extends StatefulWidget {
  /// 관리자 모드에서 떠 있는 전환 스위치에 마지막 콘텐츠가 가리지 않도록 비워둘 여백.
  final double bottomInset;

  const HomeScreen({super.key, this.bottomInset = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 15);
  static const _adminTapCount = 7;

  final _api = HydrogenApiService();

  Timer? _pollTimer;
  Timer? _tapResetTimer;
  IntegratedStatus? _status;
  bool _isLoading = true;
  bool _closedPopupShown = false;
  int _tapCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetch();
    _startPolling();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) EntryGuideDialog.show(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _tapResetTimer?.cancel();
    super.dispose();
  }

  /// 백그라운드에서 폴링을 돌릴 이유가 없다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetch();
      _startPolling();
    } else {
      _pollTimer?.cancel();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _fetch());
  }

  Future<void> _fetch() async {
    final status = await _api.getIntegratedStatus();
    if (!mounted) return;

    // 실패하면 직전 값을 유지한다 — 옥외에서 전파가 끊긴다.
    setState(() {
      if (status != null) _status = status;
      _isLoading = false;
    });

    if (status == null) return;
    context.read<StationProvider>().updateFromApi(status.station);

    if (!_closedPopupShown && !status.isOperating) {
      _closedPopupShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ClosedDialog.show(context);
      });
    }
  }

  /// 관리자 진입점. 영업중 뱃지를 없애면서 제목으로 옮겼다.
  void _handleTitleTap() {
    _tapResetTimer?.cancel();
    _tapCount++;

    if (_tapCount >= _adminTapCount) {
      _tapCount = 0;
      AdminPasswordModal.show(context);
      return;
    }
    _tapResetTimer = Timer(const Duration(seconds: 2), () => _tapCount = 0);
  }

  bool get _isLastTT {
    final tt = _status?.tt;
    if (tt == null) return false;
    return tt.totalCount > 0 && tt.currentIndex == tt.totalCount;
  }

  /// 이상한 것만 배너로 올린다. 정상은 화면에 없다.
  ///
  /// 손님에게 충전기 A/B는 의미 없는 기호라 "2기 중 1기"로 센다.
  List<Widget> _buildAlerts(StationProvider station) {
    final status = _status;
    if (status == null || !status.isOperating) return const [];

    final alerts = <Widget>[];
    final down = [station.chargerA, station.chargerB]
        .where((c) => c != ChargerStatus.operating)
        .toList();

    if (down.length == 1) {
      alerts.add(AlertBanner(
        title: S.chargerPartial(down.first.displayName),
        detail: S.chargerPartialDetail,
      ));
    } else if (down.length == 2) {
      alerts.add(const AlertBanner(
        title: S.chargerAllDown,
        detail: S.chargerAllDownDetail,
      ));
    }

    if (station.carWashStatus != CarWashStatus.operating) {
      alerts.add(AlertBanner(
        title: S.carwash(station.carWashStatus.displayName),
        detail: S.carwashDetail,
      ));
    }

    final announcement = station.announcement;
    if (announcement != null && announcement.isNotEmpty) {
      alerts.add(AlertBanner.notice(
        title: S.noticeTitle,
        detail: announcement,
      ));
    }

    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final station = context.watch<StationProvider>();
    final status = _status;

    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.orange,
          onRefresh: _fetch,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpace.xl,
              AppSpace.lg,
              AppSpace.xl,
              AppSpace.xxl + widget.bottomInset,
            ),
            children: [
              Pressable(
                scale: 0.98,
                onTap: _handleTitleTap,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    S.stationName,
                    style: AppText.screenTitle.copyWith(color: AppColors.gray900),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              if (status == null)
                // 아직 한 번도 못 받았다. 모르는 것을 아는 척하지 않는다.
                _isLoading
                    ? const HomeSkeleton()
                    : LoadFailedCard(onRetry: _fetch)
              else ...[
                for (final alert in _buildAlerts(station)) ...[
                  alert,
                  const SizedBox(height: AppSpace.md),
                ],
                WaitCard(
                  isOperating: status.isOperating,
                  waitMinutes: status.estimatedWaitMinutes,
                  waitingCars: status.waitingCars,
                  waitingBuses: status.waitingBuses,
                ),
                if (status.isOperating) ...[
                  const SizedBox(height: AppSpace.lg),
                  StockCard(isLastTT: _isLastTT, pressure: status.ttPressure),
                ],
              ],
              const SizedBox(height: AppSpace.section),
              const StationInfo(),
            ],
          ),
        ),
      ),
    );
  }
}
