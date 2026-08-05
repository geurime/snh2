/// UI 문자열. 위젯 안에 리터럴을 두지 않는다.
///
/// 문구 규칙은 CLAUDE.md의 도메인 규칙을 따른다:
/// - 대기시간엔 반드시 "약"을 붙인다 (추정값이므로)
/// - "앞에 N대" 금지 (충전 중 차량이 포함된 현황이므로)
/// - 손님에게 충전기 A/B와 T/T 순번을 노출하지 않는다
abstract final class S {
  static const stationName = '성남수소충전소';

  // ── 히어로 ──
  static const heroEyebrow = '지금 오시면';
  static const heroPrefix = '약';
  static const heroSuffix = '분 기다려요';
  static const heroNoWait = '바로 충전할 수 있어요';
  static const heroClosed = '오늘 영업 끝났어요';

  static String heroOpensAt(String time) => '내일 $time에 열어요';

  static String cars(int n) => '승용 $n대';
  static String buses(int n) => '버스 $n대';

  // ── 수소 재고 ──
  // T/T는 내부 용어라 손님 화면에 노출하지 않는다.
  static const stockTitle = '재고';
  static const stockEnough = '여유있어요';
  static const stockLast = '오늘 마지막이에요';
  static const pressureTitle = '잔압';
  static const pressureUnit = 'bar';

  static String closingAt(int bar) => '${bar}bar 마감';

  // ── 이상 안내 ──
  static String chargerPartial(String status) => '충전기 2기 중 1기 $status';
  static const chargerPartialDetail = '한 대로만 운영 중이라 평소보다 오래 걸려요';
  static const chargerAllDown = '충전기 2기 모두 사용 불가';
  static const chargerAllDownDetail = '지금은 충전할 수 없어요';

  static String carwash(String status) => '세차장 $status';
  static const carwashDetail = '오늘은 세차를 할 수 없어요';

  static const noticeTitle = '공지';

  // ── 충전소 안내 ──
  /// 없어진 "안내" 탭과 같은 이름을 써야 쓰던 사람이 헤매지 않는다.
  static const infoTitle = '안내';

  /// 연중무휴는 명절·공휴일에 올지 말지를 가르는 정보라 시간과 같은 무게로 둔다.
  static const openHours = '07:30 – 20:00 · 연중무휴';
  static const openTime = '07:30';
  static const price = '11,000원/kg';
  static const account = '농협 351-1199-9916-73';
  static const accountNumber = '351-1199-9916-73';
  static const accountCopied = '계좌번호를 복사했어요';
  static const benefit = '세차 할인권 · E1 포인트카드';

  // ── 시설 ──
  // 있는 줄 모르면 못 쓰는 것들이라 노출한다. 목록에 섞으면 묻히므로 카드로 묶는다.
  static const phone = '031-755-7600';
  static const faq = '자주 묻는 질문';

  // ── 푸터 ──
  static const privacy = '개인정보 처리방침';
  static const privacyUrl =
      'https://snh2-production.up.railway.app/privacy-policy.html';

  // ── 관리 화면 ──
  static const adminTitle = '관리';

  /// 임계값이 있는 감시 지표. 정상이면 한 줄, 넘으면 카드로 커진다.
  static const metricPressure = '평균 잔압';
  static const metricLoss = '손실률';
  static String pressureOver(int bar) => '${bar}bar를 넘었어요';
  static String lossOver(int pct) => '±$pct%를 벗어났어요 · 기기 확인이 필요합니다';

  /// 하루 흐름 순서 — 아침 T/T 입력 → 16시 매출 보고 주문량 판단 → 퇴근 전 마감.
  static const sectionWork = '업무';
  static const sectionTT = 'T/T';
  static const sectionStation = '충전소';

  static const rowTT = 'T/T';
  static const rowSalesReport = '매출 추이';
  static const rowClosing = '마감';
  static const rowChargerA = '충전기 A';
  static const rowChargerB = '충전기 B';
  static const rowCarWash = '세차장';
  static const rowNotice = '공지';

  static const notEntered = '입력 안 됨';
  static String ttCount(int n) => '$n대';
  static String salesSummary(int vehicles, double kg) =>
      '$vehicles대 · ${kg.toStringAsFixed(0)}kg';

  // 2상태 토글 라벨. 점검중은 손님에게 고장과 구분이 없어서 쓰지 않는다.
  static const chargerOk = '정상';
  static const chargerDown = '고장';
  static const washOpen = '운영';
  static const washClosed = '중단';

  static const ttEmpty = '빈통';
  static const ttReady = '대기';
  static const ttInUse = '사용 중';

  // ── 오류 ──
  static const loadFailedTitle = '정보를 불러오지 못했어요';
  static const loadFailedBody = '네트워크 상태를 확인하고 다시 시도해 주세요';
  static const retry = '다시 시도';
}

/// 잔압이 이 값 아래로 내려가면 영업을 마친다.
const kClosingPressureBar = 55;

/// 이번 달 평균 잔압이 이 값을 넘으면 낭비가 쌓이고 있다는 뜻이다. 현장 기준.
const kMaxAveragePressureBar = 65;

/// 평균 손실률이 ±이 값을 벗어나면 기기 이상을 의심한다. 표본 수와 무관하게 즉시 알린다.
const kMaxLossRatePercent = 2;
