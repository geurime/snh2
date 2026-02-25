import 'enums.dart';
import 'tt_models.dart';
import 'meal_models.dart';

/// 하잉 API 데이터 (공공 데이터)
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
