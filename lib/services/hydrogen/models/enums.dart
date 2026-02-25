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
