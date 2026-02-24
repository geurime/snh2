import 'package:dio/dio.dart';

/// 충전기 상태
enum ChargerStatus {
  operating,
  broken,
  maintenance;

  static ChargerStatus fromString(String value) {
    switch (value) {
      case 'operating':
        return ChargerStatus.operating;
      case 'broken':
        return ChargerStatus.broken;
      case 'maintenance':
        return ChargerStatus.maintenance;
      default:
        return ChargerStatus.operating;
    }
  }

  String get displayName {
    switch (this) {
      case ChargerStatus.operating:
        return '정상';
      case ChargerStatus.broken:
        return '고장';
      case ChargerStatus.maintenance:
        return '점검중';
    }
  }
}

/// 세차장 상태
enum CarWashStatus {
  operating,
  maintenance,
  closed;

  static CarWashStatus fromString(String value) {
    switch (value) {
      case 'operating':
        return CarWashStatus.operating;
      case 'maintenance':
        return CarWashStatus.maintenance;
      case 'closed':
        return CarWashStatus.closed;
      default:
        return CarWashStatus.operating;
    }
  }

  String get displayName {
    switch (this) {
      case CarWashStatus.operating:
        return '운영중';
      case CarWashStatus.maintenance:
        return '점검중';
      case CarWashStatus.closed:
        return '운영종료';
    }
  }
}

/// T/T 상태
enum TTStatus {
  empty,    // 빈통
  standby,  // 대기 (가득)
  inUse;    // 사용 중

  static TTStatus fromString(String value) {
    switch (value) {
      case 'empty':
        return TTStatus.empty;
      case 'standby':
        return TTStatus.standby;
      case 'inUse':
        return TTStatus.inUse;
      default:
        return TTStatus.empty;
    }
  }

  String get displayName {
    switch (this) {
      case TTStatus.empty:
        return '빈통';
      case TTStatus.standby:
        return '대기';
      case TTStatus.inUse:
        return '사용 중';
    }
  }
}

/// 하잉 API 데이터
class PublicData {
  final int? ttPressure;
  final int? waitingVehicles;
  final int? waitingCars;
  final int? waitingBuses;
  final String operationStatus;
  final bool isOperating;
  final String? lastUpdated;
  final int? estimatedWaitMinutes;

  PublicData({
    this.ttPressure,
    this.waitingVehicles,
    this.waitingCars,
    this.waitingBuses,
    required this.operationStatus,
    required this.isOperating,
    this.lastUpdated,
    this.estimatedWaitMinutes,
  });

  factory PublicData.fromJson(Map<String, dynamic> json) {
    return PublicData(
      ttPressure: json['ttPressure'],
      waitingVehicles: json['waitingVehicles'],
      waitingCars: json['waitingCars'],
      waitingBuses: json['waitingBuses'],
      operationStatus: json['operationStatus'] ?? '정보없음',
      isOperating: json['isOperating'] ?? false,
      lastUpdated: json['lastUpdated'],
      estimatedWaitMinutes: json['estimatedWaitMinutes'],
    );
  }
}

/// 직원 입력 충전소 데이터
class StationData {
  final ChargerStatus chargerA;
  final ChargerStatus chargerB;
  final CarWashStatus carWashStatus;
  final TTStatus ttAStatus;
  final TTStatus ttBStatus;
  final String? announcement;

  StationData({
    required this.chargerA,
    required this.chargerB,
    required this.carWashStatus,
    required this.ttAStatus,
    required this.ttBStatus,
    this.announcement,
  });

  factory StationData.fromJson(Map<String, dynamic> json) {
    return StationData(
      chargerA: ChargerStatus.fromString(json['chargerA'] ?? 'operating'),
      chargerB: ChargerStatus.fromString(json['chargerB'] ?? 'operating'),
      carWashStatus: CarWashStatus.fromString(json['carWashStatus'] ?? 'operating'),
      ttAStatus: TTStatus.fromString(json['ttAStatus'] ?? 'empty'),
      ttBStatus: TTStatus.fromString(json['ttBStatus'] ?? 'empty'),
      announcement: json['announcement'],
    );
  }
}

/// T/T 작업 결과
class TTOperationResult {
  final bool success;
  final String? message;
  final TTStatus ttAStatus;
  final TTStatus ttBStatus;

  TTOperationResult({
    required this.success,
    this.message,
    required this.ttAStatus,
    required this.ttBStatus,
  });

  factory TTOperationResult.fromJson(Map<String, dynamic> json) {
    return TTOperationResult(
      success: json['success'] ?? false,
      message: json['message'],
      ttAStatus: TTStatus.fromString(json['ttAStatus'] ?? 'empty'),
      ttBStatus: TTStatus.fromString(json['ttBStatus'] ?? 'empty'),
    );
  }
}

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

/// 오늘의 식사
class MealData {
  final String? lunch;
  final String? dinner;

  MealData({this.lunch, this.dinner});

  factory MealData.fromJson(Map<String, dynamic> json) {
    return MealData(
      lunch: json['lunch'],
      dinner: json['dinner'],
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

/// 통합 충전소 정보
class IntegratedStatus {
  final PublicData? publicData;
  final StationData station;
  final TTData tt;
  final TomorrowTTData tomorrowTT;
  final MealData meal;

  IntegratedStatus({
    this.publicData,
    required this.station,
    required this.tt,
    required this.tomorrowTT,
    required this.meal,
  });

  factory IntegratedStatus.fromJson(Map<String, dynamic> json) {
    return IntegratedStatus(
      publicData: json['public'] != null
          ? PublicData.fromJson(json['public'])
          : null,
      station: StationData.fromJson(json['station'] ?? {}),
      tt: TTData.fromJson(json['tt'] ?? {}),
      tomorrowTT: TomorrowTTData.fromJson(json['tomorrowTT'] ?? {}),
      meal: MealData.fromJson(json['meal'] ?? {}),
    );
  }

  // 편의 getter
  int? get ttPressure => publicData?.ttPressure;
  int? get waitingVehicles => publicData?.waitingVehicles;
  int? get waitingCars => publicData?.waitingCars;
  int? get waitingBuses => publicData?.waitingBuses;
  String get operationStatus => publicData?.operationStatus ?? '정보없음';
  bool get isOperating => publicData?.isOperating ?? false;
  int? get estimatedWaitMinutes => publicData?.estimatedWaitMinutes;
}

/// 수소충전소 API 서비스
class HydrogenApiService {
  static const String _baseUrl = 'https://snh2-production.up.railway.app/api';

  final Dio _dio;

  HydrogenApiService() : _dio = Dio();

  /// 통합 충전소 정보 조회
  Future<IntegratedStatus?> getIntegratedStatus() async {
    try {
      final response = await _dio.get('$_baseUrl/integrated');

      if (response.statusCode == 200) {
        return IntegratedStatus.fromJson(response.data);
      }
    } catch (e) {
      print('[HydrogenApi] Error: $e');
    }
    return null;
  }

  /// 충전기 상태 업데이트
  Future<bool> updateCharger({
    ChargerStatus? chargerA,
    ChargerStatus? chargerB,
  }) async {
    try {
      final data = <String, String>{};
      if (chargerA != null) data['chargerA'] = chargerA.name;
      if (chargerB != null) data['chargerB'] = chargerB.name;

      final response = await _dio.patch(
        '$_baseUrl/station/charger',
        data: data,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[HydrogenApi] Error: $e');
      return false;
    }
  }

  /// 세차장 상태 업데이트
  Future<bool> updateCarWash(CarWashStatus status) async {
    try {
      final response = await _dio.patch(
        '$_baseUrl/station/carwash',
        data: {'carWashStatus': status.name},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[HydrogenApi] Error: $e');
      return false;
    }
  }

  /// 공지사항 업데이트
  Future<bool> updateAnnouncement(String? announcement) async {
    try {
      final response = await _dio.patch(
        '$_baseUrl/station/announcement',
        data: {'announcement': announcement},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[HydrogenApi] Error: $e');
      return false;
    }
  }

  /// T/T 입고
  Future<TTOperationResult?> ttIncoming(String target) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/station/tt/incoming',
        data: {'target': target},
      );
      if (response.statusCode == 201) {
        return TTOperationResult.fromJson(response.data);
      }
    } catch (e) {
      print('[HydrogenApi] Error: $e');
    }
    return null;
  }

  /// T/T 교체
  Future<TTOperationResult?> ttChange(String direction, int pressureBefore) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/station/tt/change',
        data: {
          'direction': direction,
          'pressureBefore': pressureBefore,
        },
      );
      if (response.statusCode == 201) {
        return TTOperationResult.fromJson(response.data);
      }
    } catch (e) {
      print('[HydrogenApi] Error: $e');
    }
    return null;
  }

  /// T/T 현황 업데이트
  Future<bool> updateTTStatus({int? totalCount, int? currentIndex}) async {
    try {
      final data = <String, int>{};
      if (totalCount != null) data['totalCount'] = totalCount;
      if (currentIndex != null) data['currentIndex'] = currentIndex;

      final response = await _dio.patch(
        '$_baseUrl/tt/today',
        data: data,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[HydrogenApi] Error: $e');
      return false;
    }
  }

  /// T/T 상태 직접 설정 (빈통/대기/사용중)
  Future<bool> setTTStatus({required TTStatus ttAStatus, required TTStatus ttBStatus}) async {
    try {
      final response = await _dio.patch(
        '$_baseUrl/station/tt/status',
        data: {
          'ttAStatus': ttAStatus.name,
          'ttBStatus': ttBStatus.name,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[HydrogenApi] Error: $e');
      return false;
    }
  }

  /// T/T 일정 업데이트
  Future<bool> updateTTSchedule(List<String> schedules) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/tt/schedule',
        data: {'schedules': schedules},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[HydrogenApi] Error: $e');
      return false;
    }
  }

  /// 특정 날짜 T/T 일정 업데이트
  Future<bool> updateTTScheduleByDate(String date, List<String> schedules) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/tt/schedule/$date',
        data: {'schedules': schedules},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[HydrogenApi] Error: $e');
      return false;
    }
  }

  /// 오늘의 식사 업데이트
  Future<bool> updateMeal({String? lunch, String? dinner}) async {
    try {
      final data = <String, String?>{};
      if (lunch != null) data['lunch'] = lunch;
      if (dinner != null) data['dinner'] = dinner;

      final response = await _dio.put(
        '$_baseUrl/meal/today',
        data: data,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[HydrogenApi] Error: $e');
      return false;
    }
  }

  /// 특정 날짜 T/T 일정 조회
  Future<TTScheduleData?> getTTScheduleByDate(String date) async {
    try {
      final response = await _dio.get('$_baseUrl/tt/$date');
      if (response.statusCode == 200) {
        return TTScheduleData.fromJson(response.data);
      }
    } catch (e) {
      print('[HydrogenApi] Error: $e');
    }
    return null;
  }

  /// 매출 기록 조회
  Future<Map<String, dynamic>?> getSales(String date) async {
    try {
      final response = await _dio.get('$_baseUrl/sales/$date');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('[HydrogenApi] Error: $e');
    }
    return null;
  }

  /// 매출 기록 업데이트
  Future<bool> updateSales(
      String date, double totalKg, int totalVehicles, {double? flowMeter}) async {
    try {
      final data = <String, dynamic>{
        'totalKg': totalKg,
        'totalVehicles': totalVehicles,
      };
      if (flowMeter != null) {
        data['flowMeter'] = flowMeter;
      }
      final response = await _dio.put(
        '$_baseUrl/sales/$date',
        data: data,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[HydrogenApi] Error: $e');
      return false;
    }
  }

  /// 업무 일지 조회
  Future<WorklogData?> getWorklog(String date) async {
    try {
      final response = await _dio.get('$_baseUrl/worklog/$date');
      if (response.statusCode == 200) {
        return WorklogData.fromJson(response.data);
      }
    } catch (e) {
      print('[HydrogenApi] Error: $e');
    }
    return null;
  }

  /// 오늘 업무 일지 조회
  Future<WorklogData?> getTodayWorklog() async {
    try {
      final response = await _dio.get('$_baseUrl/worklog/today');
      if (response.statusCode == 200) {
        return WorklogData.fromJson(response.data);
      }
    } catch (e) {
      print('[HydrogenApi] Error: $e');
    }
    return null;
  }

  /// 특이사항 검색 (최근 3개월)
  Future<List<NotesSearchResult>> searchNotes(String keyword) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/worklog/search',
        queryParameters: {'keyword': keyword},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => NotesSearchResult.fromJson(e)).toList();
      }
    } catch (e) {
      print('[HydrogenApi] Error: $e');
    }
    return [];
  }

  /// T/T 입출고 기록 추가
  Future<bool> addTTInOut(String date, TTInOutRecord record) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/worklog/$date/tt-inout',
        data: {'record': record.toJson()},
      );
      return response.statusCode == 201;
    } catch (e) {
      print('[HydrogenApi] Error: $e');
      return false;
    }
  }

  /// T/T 입출고 기록 삭제
  Future<bool> deleteTTInOut(String date, int index) async {
    try {
      final response = await _dio.delete('$_baseUrl/worklog/$date/tt-inout/$index');
      return response.statusCode == 200;
    } catch (e) {
      print('[HydrogenApi] Error: $e');
      return false;
    }
  }

  /// T/T 교체 기록 추가
  Future<bool> addTTChange(String date, TTChangeRecord record) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/worklog/$date/tt-change',
        data: {'record': record.toJson()},
      );
      return response.statusCode == 201;
    } catch (e) {
      print('[HydrogenApi] Error: $e');
      return false;
    }
  }

  /// T/T 교체 기록 삭제
  Future<bool> deleteTTChange(String date, int index) async {
    try {
      final response = await _dio.delete('$_baseUrl/worklog/$date/tt-change/$index');
      return response.statusCode == 200;
    } catch (e) {
      print('[HydrogenApi] Error: $e');
      return false;
    }
  }

  /// 업무 일지 특이사항 업데이트
  Future<bool> updateWorklogNotes(String date, String? notes) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/worklog/$date/notes',
        data: {'notes': notes},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[HydrogenApi] Error: $e');
      return false;
    }
  }

  /// 월별 평균 잔압 조회
  Future<MonthlyPressureStats?> getMonthlyPressureStats(int year, int month) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/worklog/stats/pressure',
        queryParameters: {'year': year, 'month': month},
      );
      if (response.statusCode == 200) {
        return MonthlyPressureStats.fromJson(response.data);
      }
    } catch (e) {
      print('[HydrogenApi] Error: $e');
    }
    return null;
  }

  /// 월별 평균 손실률 조회
  Future<MonthlyLossStats?> getMonthlyLossStats(int year, int month) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/worklog/stats/loss',
        queryParameters: {'year': year, 'month': month},
      );
      if (response.statusCode == 200) {
        return MonthlyLossStats.fromJson(response.data);
      }
    } catch (e) {
      print('[HydrogenApi] Error: $e');
    }
    return null;
  }

  /// 월별 매출 통계 조회
  Future<MonthlySalesStats?> getMonthlySalesStats(int year, int month) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/sales/stats/monthly',
        queryParameters: {'year': year, 'month': month},
      );
      if (response.statusCode == 200) {
        return MonthlySalesStats.fromJson(response.data);
      }
    } catch (e) {
      print('[HydrogenApi] Error: $e');
    }
    return null;
  }

  /// 날짜 범위 매출 조회 (그래프용)
  Future<List<DailySales>?> getSalesRange(String startDate, String endDate) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/sales/range',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((e) => DailySales.fromJson(e))
            .toList();
      }
    } catch (e) {
      print('[HydrogenApi] Error: $e');
    }
    return null;
  }

  /// 건의사항 제출
  Future<bool> submitSuggestion(String content) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/suggestion',
        data: {'content': content},
      );
      return response.statusCode == 201;
    } catch (e) {
      print('[HydrogenApi] Error: $e');
      return false;
    }
  }

  /// 건의사항 목록 조회
  Future<List<Suggestion>?> getSuggestions() async {
    try {
      final response = await _dio.get('$_baseUrl/suggestion');
      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((e) => Suggestion.fromJson(e))
            .toList();
      }
    } catch (e) {
      print('[HydrogenApi] Error: $e');
    }
    return null;
  }
}

/// 건의사항
class Suggestion {
  final int id;
  final String content;
  final DateTime createdAt;

  Suggestion({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// T/T 일정 데이터 (날짜별)
class TTScheduleData {
  final String date;
  final int totalCount;
  final int currentIndex;
  final List<String> schedules;

  TTScheduleData({
    required this.date,
    required this.totalCount,
    required this.currentIndex,
    required this.schedules,
  });

  factory TTScheduleData.fromJson(Map<String, dynamic> json) {
    return TTScheduleData(
      date: json['date'] ?? '',
      totalCount: json['totalCount'] ?? 0,
      currentIndex: json['currentIndex'] ?? 0,
      schedules: (json['schedules'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// T/T 입출고 기록
class TTInOutRecord {
  final String time;
  final String description;

  TTInOutRecord({required this.time, required this.description});

  factory TTInOutRecord.fromJson(Map<String, dynamic> json) {
    return TTInOutRecord(
      time: json['time'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'description': description,
    };
  }
}

/// T/T 교체 기록
class TTChangeRecord {
  final String time;
  final String direction;
  final double meterValue;
  final int monthlyIndex;
  final int pressureBefore;

  TTChangeRecord({
    required this.time,
    required this.direction,
    required this.meterValue,
    required this.monthlyIndex,
    required this.pressureBefore,
  });

  factory TTChangeRecord.fromJson(Map<String, dynamic> json) {
    return TTChangeRecord(
      time: json['time'] ?? '',
      direction: json['direction'] ?? '',
      meterValue: (json['meterValue'] ?? 0).toDouble(),
      monthlyIndex: json['monthlyIndex'] ?? 0,
      pressureBefore: json['pressureBefore'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'direction': direction,
      'meterValue': meterValue,
      'monthlyIndex': monthlyIndex,
      'pressureBefore': pressureBefore,
    };
  }
}

/// 특이사항 검색 결과
class NotesSearchResult {
  final String date;
  final String notes;

  NotesSearchResult({
    required this.date,
    required this.notes,
  });

  factory NotesSearchResult.fromJson(Map<String, dynamic> json) {
    return NotesSearchResult(
      date: json['date'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}

/// 업무 일지 데이터
class WorklogData {
  final String date;
  final List<TTInOutRecord> ttInOutRecords;
  final List<TTChangeRecord> ttChangeRecords;
  final String? notes;

  WorklogData({
    required this.date,
    required this.ttInOutRecords,
    required this.ttChangeRecords,
    this.notes,
  });

  factory WorklogData.fromJson(Map<String, dynamic> json) {
    return WorklogData(
      date: json['date'] ?? '',
      ttInOutRecords: (json['ttInOutRecords'] as List<dynamic>?)
              ?.map((e) => TTInOutRecord.fromJson(e))
              .toList() ??
          [],
      ttChangeRecords: (json['ttChangeRecords'] as List<dynamic>?)
              ?.map((e) => TTChangeRecord.fromJson(e))
              .toList() ??
          [],
      notes: json['notes'],
    );
  }
}

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
