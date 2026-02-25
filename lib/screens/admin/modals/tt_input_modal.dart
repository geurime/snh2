import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/colors.dart';
import '../../../services/hydrogen_api.dart';

class TTInputModal extends StatefulWidget {
  final List<String> todaySchedules;
  final List<String> tomorrowSchedules;
  final Function(List<String> today, List<String> tomorrow) onSave;

  const TTInputModal({
    super.key,
    required this.todaySchedules,
    required this.tomorrowSchedules,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> todaySchedules,
    required List<String> tomorrowSchedules,
    required Function(List<String> today, List<String> tomorrow) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TTInputModal(
        todaySchedules: todaySchedules,
        tomorrowSchedules: tomorrowSchedules,
        onSave: onSave,
      ),
    );
  }

  @override
  State<TTInputModal> createState() => _TTInputModalState();
}

class _TTInputModalState extends State<TTInputModal> {
  late List<String> _todaySchedules;
  late List<String> _tomorrowSchedules;
  final _timeController = TextEditingController();
  final _apiService = HydrogenApiService();
  bool _isToday = true;

  @override
  void initState() {
    super.initState();
    _todaySchedules = List.from(widget.todaySchedules);
    _tomorrowSchedules = List.from(widget.tomorrowSchedules);
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  List<String> get _currentSchedules =>
      _isToday ? _todaySchedules : _tomorrowSchedules;

  void _addSchedule() {
    final time = _timeController.text.trim();
    if (time.isEmpty) return;

    setState(() {
      if (_isToday) {
        _todaySchedules.add(time);
      } else {
        _tomorrowSchedules.add(time);
      }
      _timeController.clear();
    });
  }

  void _removeSchedule(int index) {
    setState(() {
      if (_isToday) {
        _todaySchedules.removeAt(index);
      } else {
        _tomorrowSchedules.removeAt(index);
      }
    });
  }

  Future<void> _save() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0];

    final todaySuccess = await _apiService.updateTTScheduleByDate(today, _todaySchedules);
    final tomorrowSuccess = await _apiService.updateTTScheduleByDate(tomorrow, _tomorrowSchedules);

    if ((todaySuccess || tomorrowSuccess) && mounted) {
      widget.onSave(_todaySchedules, _tomorrowSchedules);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('T/T 일정이 저장되었습니다'),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            'T/T 일정 관리',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isToday = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          _isToday ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '오늘',
                        style: TextStyle(
                          color: _isToday ? Colors.white : AppColors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isToday = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          !_isToday ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '내일',
                        style: TextStyle(
                          color: !_isToday ? Colors.white : AppColors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    hintText: '시간 입력 (예: 09:30)',
                    hintStyle:
                        TextStyle(color: AppColors.black.withOpacity(0.4)),
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
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _addSchedule,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.plus,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _currentSchedules.isEmpty
                ? Center(
                    child: Text(
                      '등록된 일정이 없습니다',
                      style: TextStyle(
                        color: AppColors.black.withOpacity(0.5),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _currentSchedules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${index + 1}차 - ${_currentSchedules[index]}',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.black,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _removeSchedule(index),
                              child: Icon(
                                LucideIcons.x,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
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
    );
  }
}
