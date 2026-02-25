import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/station_provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/hydrogen_api.dart';
import '../../widgets/banner_slider.dart';

import 'widgets/operation_badge.dart';
import 'widgets/announcement_banner.dart';
import 'widgets/last_tt_banner.dart';
import 'widgets/status_card.dart';
import 'widgets/charger_card.dart';
import 'widgets/tt_card.dart';
import 'widgets/info_banner.dart';
import 'skeletons/status_skeleton.dart';
import 'skeletons/charger_skeleton.dart';
import 'skeletons/tt_skeleton.dart';
import 'dialogs/entry_guide_dialog.dart';
import 'dialogs/closed_dialog.dart';
import 'dialogs/admin_password_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  Timer? _apiTimer;

  final HydrogenApiService _apiService = HydrogenApiService();
  IntegratedStatus? _status;
  bool _isLoading = true;
  bool _showInfoBanner = false;

  int _adminTapCount = 0;
  Timer? _adminTapTimer;
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

  Future<void> _checkEntryGuidePopup() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EntryGuideDialog.show(context);
    });
  }

  void _startApiTimer() {
    _apiTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchStatus();
    });
  }

  Future<void> _fetchStatus() async {
    final status = await _apiService.getIntegratedStatus();
    if (mounted) {
      setState(() {
        if (status != null) {
          _status = status;
        }
        _isLoading = false;
      });
      if (status != null) {
        context.read<StationProvider>().updateFromApi(status.station);
        if (!_closedPopupShown && !status.isOperating) {
          _closedPopupShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ClosedDialog.show(context);
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

  void _handleAdminTap() {
    _adminTapTimer?.cancel();
    _adminTapCount++;

    if (_adminTapCount >= 7) {
      _adminTapCount = 0;
      AdminPasswordModal.show(context);
    } else {
      _adminTapTimer = Timer(const Duration(seconds: 2), () {
        _adminTapCount = 0;
      });
    }
  }

  void _showInfoBannerTemporarily() {
    setState(() => _showInfoBanner = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showInfoBanner = false);
      }
    });
  }

  bool get _isLastTT {
    if (_status == null) return false;
    final tt = _status!.tt;
    return tt.totalCount > 0 && tt.currentIndex == tt.totalCount;
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
                  _buildHeader(),
                  const SizedBox(height: 16),
                  if (_isLastTT) ...[
                    const LastTTBanner(),
                    const SizedBox(height: 16),
                  ],
                  _buildAnnouncement(),
                  _buildStatusSection(),
                  const SizedBox(height: 16),
                  _buildChargerSection(),
                  const SizedBox(height: 16),
                  _buildTTSection(),
                  const SizedBox(height: 16),
                  const BannerSlider(),
                ],
              ),
            ),
          ),
          if (_showInfoBanner)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 20,
              right: 20,
              child: InfoBanner(isVisible: _showInfoBanner),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
        OperationBadge(
          status: _status,
          isLoading: _isLoading,
          onTap: _handleAdminTap,
        ),
      ],
    );
  }

  Widget _buildAnnouncement() {
    final announcement = context.watch<StationProvider>().announcement;
    if (announcement == null || announcement.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnnouncementBanner(announcement: announcement),
    );
  }

  Widget _buildStatusSection() {
    if (_isLoading) {
      return const StatusCardSkeleton();
    }
    return StatusCard(
      status: _status,
      onInfoTap: _showInfoBannerTemporarily,
    );
  }

  Widget _buildChargerSection() {
    if (_isLoading) {
      return const ChargerCardSkeleton();
    }
    return const ChargerCard();
  }

  Widget _buildTTSection() {
    if (_isLoading) {
      return const TTCardSkeleton();
    }
    return TTCard(status: _status);
  }
}
