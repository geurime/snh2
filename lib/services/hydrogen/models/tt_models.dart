/// T/T 현황
class TTData {
  final int totalCount;
  final int currentIndex;
  final List<String> schedules;

  TTData({
    required this.totalCount,
    required this.currentIndex,
    required this.schedules,
  });

  factory TTData.fromJson(Map<String, dynamic> json) {
    return TTData(
      totalCount: json['totalCount'] ?? 0,
      currentIndex: json['currentIndex'] ?? 0,
      schedules: (json['schedules'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// 내일 T/T 일정
class TomorrowTTData {
  final List<String> schedules;

  TomorrowTTData({required this.schedules});

  factory TomorrowTTData.fromJson(Map<String, dynamic> json) {
    return TomorrowTTData(
      schedules: (json['schedules'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

