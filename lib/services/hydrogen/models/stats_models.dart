/// 월별 평균 잔압 통계
class MonthlyPressureStats {
  final int year;
  final int month;
  final int totalPressureSum;
  final int recordCount;
  final double averagePressure;

  MonthlyPressureStats({
    required this.year,
    required this.month,
    required this.totalPressureSum,
    required this.recordCount,
    required this.averagePressure,
  });

  factory MonthlyPressureStats.fromJson(Map<String, dynamic> json) {
    return MonthlyPressureStats(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      totalPressureSum: json['totalPressureSum'] ?? 0,
      recordCount: json['recordCount'] ?? 0,
      averagePressure: (json['averagePressure'] ?? 0).toDouble(),
    );
  }
}

/// 월별 평균 손실률 통계
class MonthlyLossStats {
  final int year;
  final int month;
  final int recordCount;
  final double averageLossRate;

  MonthlyLossStats({
    required this.year,
    required this.month,
    required this.recordCount,
    required this.averageLossRate,
  });

  factory MonthlyLossStats.fromJson(Map<String, dynamic> json) {
    return MonthlyLossStats(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      recordCount: json['recordCount'] ?? 0,
      averageLossRate: (json['averageLossRate'] ?? 0).toDouble(),
    );
  }
}

/// 월별 매출 통계
class MonthlySalesStats {
  final int year;
  final int month;
  final double totalKg;
  final int totalVehicles;
  final int recordCount;
  final double dailyAvgKg;
  final double dailyAvgVehicles;

  MonthlySalesStats({
    required this.year,
    required this.month,
    required this.totalKg,
    required this.totalVehicles,
    required this.recordCount,
    required this.dailyAvgKg,
    required this.dailyAvgVehicles,
  });

  factory MonthlySalesStats.fromJson(Map<String, dynamic> json) {
    return MonthlySalesStats(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      totalKg: (json['totalKg'] ?? 0).toDouble(),
      totalVehicles: json['totalVehicles'] ?? 0,
      recordCount: json['recordCount'] ?? 0,
      dailyAvgKg: (json['dailyAvgKg'] ?? 0).toDouble(),
      dailyAvgVehicles: (json['dailyAvgVehicles'] ?? 0).toDouble(),
    );
  }
}

/// 일별 매출 데이터
class DailySales {
  final String date;
  final double totalKg;
  final int totalVehicles;

  DailySales({
    required this.date,
    required this.totalKg,
    required this.totalVehicles,
  });

  factory DailySales.fromJson(Map<String, dynamic> json) {
    return DailySales(
      date: json['date'] ?? '',
      totalKg: (json['totalKg'] ?? 0).toDouble(),
      totalVehicles: json['totalVehicles'] ?? 0,
    );
  }
}
