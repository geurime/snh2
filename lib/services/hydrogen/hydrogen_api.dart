import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import 'models/models.dart';

// 기존 import 호환성을 위한 re-export
export 'models/models.dart';

/// 수소충전소 API 서비스 (싱글톤)
class HydrogenApiService {
  static final HydrogenApiService _instance = HydrogenApiService._internal();
  factory HydrogenApiService() => _instance;

  final ApiClient _client;

  HydrogenApiService._internal() : _client = ApiClient();

  /// 인증 토큰 설정
  void setAccessToken(String? token) {
    _client.setAccessToken(token);
  }

  /// 현재 토큰 확인
  bool get hasToken => _client.hasToken;

  // ==================== 공개 API ====================

  /// 통합 충전소 정보 조회
  Future<IntegratedStatus?> getIntegratedStatus() async {
    try {
      return await _client.get(
        '/integrated',
        fromJson: (data) => IntegratedStatus.fromJson(data),
      );
    } on ApiException {
      return null;
    }
  }

  /// 특정 날짜 T/T 일정 조회
  Future<TTScheduleData?> getTTScheduleByDate(String date) async {
    try {
      return await _client.get(
        '/tt/$date',
        fromJson: (data) => TTScheduleData.fromJson(data),
      );
    } on ApiException {
      return null;
    }
  }

  /// 매출 기록 조회
  Future<Map<String, dynamic>?> getSales(String date) async {
    try {
      return await _client.get('/sales/$date');
    } on ApiException {
      return null;
    }
  }

  /// 업무 일지 조회
  Future<WorklogData?> getWorklog(String date) async {
    try {
      return await _client.get(
        '/worklog/$date',
        fromJson: (data) => WorklogData.fromJson(data),
      );
    } on ApiException {
      return null;
    }
  }

  /// 오늘 업무 일지 조회
  Future<WorklogData?> getTodayWorklog() async {
    try {
      return await _client.get(
        '/worklog/today',
        fromJson: (data) => WorklogData.fromJson(data),
      );
    } on ApiException {
      return null;
    }
  }

  /// 특이사항 검색 (최근 3개월)
  Future<List<NotesSearchResult>> searchNotes(String keyword) async {
    try {
      final data = await _client.get<List<dynamic>>(
        '/worklog/search',
        queryParameters: {'keyword': keyword},
      );
      return data?.map((e) => NotesSearchResult.fromJson(e)).toList() ?? [];
    } on ApiException {
      return [];
    }
  }

  /// 월별 평균 잔압 조회
  Future<MonthlyPressureStats?> getMonthlyPressureStats(int year, int month) async {
    try {
      return await _client.get(
        '/worklog/stats/pressure',
        queryParameters: {'year': year, 'month': month},
        fromJson: (data) => MonthlyPressureStats.fromJson(data),
      );
    } on ApiException {
      return null;
    }
  }

  /// 월별 평균 손실률 조회
  Future<MonthlyLossStats?> getMonthlyLossStats(int year, int month) async {
    try {
      return await _client.get(
        '/worklog/stats/loss',
        queryParameters: {'year': year, 'month': month},
        fromJson: (data) => MonthlyLossStats.fromJson(data),
      );
    } on ApiException {
      return null;
    }
  }

  /// 월별 매출 통계 조회
  Future<MonthlySalesStats?> getMonthlySalesStats(int year, int month) async {
    try {
      return await _client.get(
        '/sales/stats/monthly',
        queryParameters: {'year': year, 'month': month},
        fromJson: (data) => MonthlySalesStats.fromJson(data),
      );
    } on ApiException {
      return null;
    }
  }

  /// 날짜 범위 매출 조회 (그래프용)
  Future<List<DailySales>?> getSalesRange(String startDate, String endDate) async {
    try {
      final data = await _client.get<List<dynamic>>(
        '/sales/range',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      return data?.map((e) => DailySales.fromJson(e)).toList();
    } on ApiException {
      return null;
    }
  }

  /// 건의사항 제출
  Future<bool> submitSuggestion(String content) async {
    try {
      await _client.post('/suggestion', data: {'content': content});
      return true;
    } on ApiException {
      return false;
    }
  }

  /// 건의사항 목록 조회
  Future<List<Suggestion>?> getSuggestions() async {
    try {
      final data = await _client.get<List<dynamic>>('/suggestion');
      return data?.map((e) => Suggestion.fromJson(e)).toList();
    } on ApiException {
      return null;
    }
  }

  // ==================== 관리자 API ====================

  /// 충전기 상태 업데이트 (관리자 전용)
  Future<bool> updateCharger({
    ChargerStatus? chargerA,
    ChargerStatus? chargerB,
  }) async {
    try {
      final data = <String, String>{};
      if (chargerA != null) data['chargerA'] = chargerA.name;
      if (chargerB != null) data['chargerB'] = chargerB.name;

      return await _client.patch(
        '/station/charger',
        data: data,
        requiresAuth: true,
      );
    } on ApiException {
      return false;
    }
  }

  /// 세차장 상태 업데이트 (관리자 전용)
  Future<bool> updateCarWash(CarWashStatus status) async {
    try {
      return await _client.patch(
        '/station/carwash',
        data: {'carWashStatus': status.name},
        requiresAuth: true,
      );
    } on ApiException {
      return false;
    }
  }

  /// 공지사항 업데이트 (관리자 전용)
  Future<bool> updateAnnouncement(String? announcement) async {
    try {
      return await _client.patch(
        '/station/announcement',
        data: {'announcement': announcement},
        requiresAuth: true,
      );
    } on ApiException {
      return false;
    }
  }

  /// T/T 입고 (관리자 전용)
  Future<TTOperationResult?> ttIncoming(String target) async {
    try {
      return await _client.post(
        '/station/tt/incoming',
        data: {'target': target},
        fromJson: (data) => TTOperationResult.fromJson(data),
        requiresAuth: true,
      );
    } on ApiException {
      return null;
    }
  }

  /// T/T 교체 (관리자 전용)
  Future<TTOperationResult?> ttChange(String direction, int pressureBefore) async {
    try {
      return await _client.post(
        '/station/tt/change',
        data: {
          'direction': direction,
          'pressureBefore': pressureBefore,
        },
        fromJson: (data) => TTOperationResult.fromJson(data),
        requiresAuth: true,
      );
    } on ApiException {
      return null;
    }
  }

  /// T/T 현황 업데이트 (관리자 전용)
  Future<bool> updateTTStatus({int? totalCount, int? currentIndex}) async {
    try {
      final data = <String, int>{};
      if (totalCount != null) data['totalCount'] = totalCount;
      if (currentIndex != null) data['currentIndex'] = currentIndex;

      return await _client.patch(
        '/tt/today',
        data: data,
        requiresAuth: true,
      );
    } on ApiException {
      return false;
    }
  }

  /// T/T 상태 직접 설정 (관리자 전용)
  Future<bool> setTTStatus({required TTStatus ttAStatus, required TTStatus ttBStatus}) async {
    try {
      return await _client.patch(
        '/station/tt/status',
        data: {
          'ttAStatus': ttAStatus.name,
          'ttBStatus': ttBStatus.name,
        },
        requiresAuth: true,
      );
    } on ApiException {
      return false;
    }
  }

  /// T/T 일정 업데이트 (관리자 전용)
  Future<bool> updateTTSchedule(List<String> schedules) async {
    try {
      return await _client.put(
        '/tt/schedule',
        data: {'schedules': schedules},
        requiresAuth: true,
      );
    } on ApiException {
      return false;
    }
  }

  /// 특정 날짜 T/T 일정 업데이트 (관리자 전용)
  Future<bool> updateTTScheduleByDate(String date, List<String> schedules) async {
    try {
      return await _client.put(
        '/tt/schedule/$date',
        data: {'schedules': schedules},
        requiresAuth: true,
      );
    } on ApiException {
      return false;
    }
  }

  /// 오늘의 식사 업데이트 (관리자 전용)
  Future<bool> updateMeal({String? lunch, String? dinner}) async {
    try {
      final data = <String, String?>{};
      if (lunch != null) data['lunch'] = lunch;
      if (dinner != null) data['dinner'] = dinner;

      return await _client.put(
        '/meal/today',
        data: data,
        requiresAuth: true,
      );
    } on ApiException {
      return false;
    }
  }

  /// 매출 기록 업데이트 (관리자 전용)
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
      return await _client.put(
        '/sales/$date',
        data: data,
        requiresAuth: true,
      );
    } on ApiException {
      return false;
    }
  }

  /// T/T 입출고 기록 추가 (관리자 전용)
  Future<bool> addTTInOut(String date, TTInOutRecord record) async {
    try {
      await _client.post(
        '/worklog/$date/tt-inout',
        data: {'record': record.toJson()},
        requiresAuth: true,
      );
      return true;
    } on ApiException {
      return false;
    }
  }

  /// T/T 입출고 기록 삭제 (관리자 전용)
  Future<bool> deleteTTInOut(String date, int index) async {
    try {
      return await _client.delete(
        '/worklog/$date/tt-inout/$index',
        requiresAuth: true,
      );
    } on ApiException {
      return false;
    }
  }

  /// T/T 교체 기록 추가 (관리자 전용)
  Future<bool> addTTChange(String date, TTChangeRecord record) async {
    try {
      await _client.post(
        '/worklog/$date/tt-change',
        data: {'record': record.toJson()},
        requiresAuth: true,
      );
      return true;
    } on ApiException {
      return false;
    }
  }

  /// T/T 교체 기록 삭제 (관리자 전용)
  Future<bool> deleteTTChange(String date, int index) async {
    try {
      return await _client.delete(
        '/worklog/$date/tt-change/$index',
        requiresAuth: true,
      );
    } on ApiException {
      return false;
    }
  }

  /// 업무 일지 특이사항 업데이트 (관리자 전용)
  Future<bool> updateWorklogNotes(String date, String? notes) async {
    try {
      return await _client.put(
        '/worklog/$date/notes',
        data: {'notes': notes},
        requiresAuth: true,
      );
    } on ApiException {
      return false;
    }
  }
}
