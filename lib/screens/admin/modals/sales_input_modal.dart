import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/spacing.dart';
import '../../../constants/typography.dart';
import '../../../widgets/pressable.dart';
import '../../../widgets/sheet_header.dart';
import '../../../services/hydrogen_api.dart';

class SalesInputModal extends StatefulWidget {
  final double? initialFlowMeter;
  final double? initialSalesKg;
  final int? initialSalesCount;

  /// 서버가 미입력 날짜에도 `totalKg: 0, totalVehicles: 0`을 채워 보낸다.
  /// null 체크만으로는 "아직 안 함"과 "0으로 입력함"이 구분되지 않아
  /// 입력칸에 0이 미리 박히고, 직원이 매번 지우고 다시 쳐야 했다.
  final bool hasRecord;

  final Function(double? flowMeter, double? salesKg, int? salesCount) onSave;

  const SalesInputModal({
    super.key,
    this.initialFlowMeter,
    this.initialSalesKg,
    this.initialSalesCount,
    this.hasRecord = false,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    double? initialFlowMeter,
    double? initialSalesKg,
    int? initialSalesCount,
    bool hasRecord = false,
    required Function(double? flowMeter, double? salesKg, int? salesCount)
        onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (context) => SalesInputModal(
        initialFlowMeter: initialFlowMeter,
        initialSalesKg: initialSalesKg,
        initialSalesCount: initialSalesCount,
        hasRecord: hasRecord,
        onSave: onSave,
      ),
    );
  }

  @override
  State<SalesInputModal> createState() => _SalesInputModalState();
}

class _SalesInputModalState extends State<SalesInputModal> {
  late final TextEditingController _flowMeterController;
  late final TextEditingController _salesKgController;
  late final TextEditingController _salesCountController;
  final _apiService = HydrogenApiService();

  @override
  void initState() {
    super.initState();
    _flowMeterController = TextEditingController(
      text: _trimZero(widget.initialFlowMeter),
    );
    // 레코드가 없으면 값이 와도 서버가 채운 0이므로 빈 칸으로 둔다.
    _salesKgController = TextEditingController(
      text: widget.hasRecord ? _trimZero(widget.initialSalesKg) : '',
    );
    _salesCountController = TextEditingController(
      text: widget.hasRecord ? (widget.initialSalesCount?.toString() ?? '') : '',
    );
  }

  /// 394.0kg처럼 소수점이 없는 값은 정수로 — 편집할 때 `.0`을 지우는 손이 준다.
  static String _trimZero(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toString();
  }

  @override
  void dispose() {
    _flowMeterController.dispose();
    _salesKgController.dispose();
    _salesCountController.dispose();
    super.dispose();
  }

  bool get _isFlowMeterInvalid {
    final text = _flowMeterController.text.trim();
    if (text.isEmpty) return false;
    final intPart = text.split('.').first;
    return intPart.length != 6;
  }

  Future<void> _save() async {
    final flowMeter = double.tryParse(_flowMeterController.text);
    final salesKg = double.tryParse(_salesKgController.text);
    final salesCount = int.tryParse(_salesCountController.text);

    final today = DateTime.now().toIso8601String().split('T')[0];

    if (salesKg == null || salesCount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('판매량과 충전 대수를 입력해주세요'),
          backgroundColor: AppColors.gray900,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isFlowMeterInvalid) return;

    final success = await _apiService.updateSales(
      today,
      salesKg,
      salesCount,
      flowMeter: flowMeter,
    );

    if (success && mounted) {
      widget.onSave(flowMeter, salesKg, salesCount);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('마감 데이터가 저장되었습니다'),
          backgroundColor: AppColors.gray900,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHeader(title: '마감 입력'),
            const SizedBox(height: 24),
            Text(
              '유량계 (kg)',
              style: AppText.label.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _flowMeterController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              style: AppText.body.copyWith(color: AppColors.gray900),
              decoration: InputDecoration(
                hintText: '428001',
                hintStyle: AppText.body.copyWith(color: AppColors.gray600),
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: _isFlowMeterInvalid
                    ? Padding(
                        padding: const EdgeInsets.only(right: AppSpace.md),
                        child: Text(
                          '6자리가 아닙니다',
                          style: AppText.label.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.orangeText,
                          ),
                        ),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(minHeight: 0),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '판매량 (kg)',
              style: AppText.label.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _salesKgController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppText.body.copyWith(color: AppColors.gray900),
              decoration: InputDecoration(
                hintText: '394',
                hintStyle: AppText.body.copyWith(color: AppColors.gray600),
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '충전 대수',
              style: AppText.label.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _salesCountController,
              keyboardType: TextInputType.number,
              style: AppText.body.copyWith(color: AppColors.gray900),
              decoration: InputDecoration(
                hintText: '78',
                hintStyle: AppText.body.copyWith(color: AppColors.gray600),
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Pressable(
              onTap: _save,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 52),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  '저장',
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
    );
  }
}
