import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../services/hydrogen_api.dart';

class SalesInputModal extends StatefulWidget {
  final double? initialFlowMeter;
  final double? initialSalesKg;
  final int? initialSalesCount;
  final Function(double? flowMeter, double? salesKg, int? salesCount) onSave;

  const SalesInputModal({
    super.key,
    this.initialFlowMeter,
    this.initialSalesKg,
    this.initialSalesCount,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    double? initialFlowMeter,
    double? initialSalesKg,
    int? initialSalesCount,
    required Function(double? flowMeter, double? salesKg, int? salesCount)
        onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SalesInputModal(
        initialFlowMeter: initialFlowMeter,
        initialSalesKg: initialSalesKg,
        initialSalesCount: initialSalesCount,
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
      text: widget.initialFlowMeter?.toString() ?? '',
    );
    _salesKgController = TextEditingController(
      text: widget.initialSalesKg?.toString() ?? '',
    );
    _salesCountController = TextEditingController(
      text: widget.initialSalesCount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _flowMeterController.dispose();
    _salesKgController.dispose();
    _salesCountController.dispose();
    super.dispose();
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
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
          backgroundColor: Color(0xFF4CAF50),
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
                '마감 입력',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '유량계 (kg)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _flowMeterController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '유량계 값 입력',
                hintStyle: TextStyle(color: AppColors.black.withOpacity(0.4)),
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
            const SizedBox(height: 16),
            Text(
              '판매량 (kg)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _salesKgController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '판매량 입력',
                hintStyle: TextStyle(color: AppColors.black.withOpacity(0.4)),
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
                hintText: '충전 대수 입력',
                hintStyle: TextStyle(color: AppColors.black.withOpacity(0.4)),
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
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _save,
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
  }
}
