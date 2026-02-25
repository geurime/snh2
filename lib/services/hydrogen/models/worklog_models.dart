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
