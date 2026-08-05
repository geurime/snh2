# 하이 (snh2) — 코드 규칙

> 8년차 이상 시니어 엔지니어 수준의 코드 품질을 유지한다.
> 핵심 원칙: **불가능한 상태를 타입으로 차단하고, 추상화는 반복이 3번 이상일 때만 한다.**
> AI(Claude, GPT 등)가 이 프로젝트의 코드를 작성·수정할 때 따라야 할 가이드라인.

---

## 프로덕트 개요

- E1 성남시 수소충전소 납품 앱. Play Store / App Store 출시 중.
- 실시간 대기 현황 · T/T 잔압을 제공. 백엔드는 [`snh2-backend`](./snh2-backend/README.md) (NestJS + PostgreSQL).
- 데이터 출처: 한국석유관리원 수소충전소 운영정보 API(하잉), 15초 폴링.

### 사용자가 둘이고, 원칙이 정반대다

| | 손님 | 직원 |
|---|---|---|
| 로그인 | 없음 | 필요 |
| 체류 | 5초 보고 나감 | 하루 종일 |
| 설계 목표 | **적게 보여주고 대신 판단해준다** | **많이 보여주고 빨리 입력하게 한다** |

**손님 화면에 직원용 밀도를 적용하지 말 것. 반대도 마찬가지.**

### 이 앱의 포지션 (★ 설계 판단의 근거)

- **설치는 사실상 전원 현장 QR.** 홍보를 하지 않는다. → 앱을 깐 사람은 **이미 여기 오는 사람**이다.
  따라서 이 앱은 충전소를 *찾는* 도구가 아니라 **"지금 갈까 이따 갈까"를 정하는 도구**다.
  길찾기·주소 같은 유치용 정보를 넣지 않는다.
- **하잉·하이케어가 이미 잔압을 보여준다.** 수소차 오너는 잔압으로 판단하는 데 익숙하다.
  우리가 더할 수 있는 건 두 개뿐이다 — **이게 오늘 마지막 T/T인가**, **몇 bar에서 마감하는가**.
  현장만 아는 정보고, 이것이 이 앱의 존재 이유다.
- 우리가 더할 게 없는 정보는 **보여주지 않는다.** 손님이 하잉을 또 켜게 만들지도 않는다.

---

## 언어

- 코드 (변수, 함수, 클래스, 위젯): 영어
- 주석: 한국어. **"왜(why)"만 적는다.** "무엇(what)"은 코드로 설명
- 커밋 메시지: 한국어
- UI 텍스트: 한국어 직접 사용 (i18n 없음). 단 **하드코딩 금지** → `lib/constants/strings.dart`에 모은다

---

## Git

### 커밋 메시지 (한국어 Conventional Commits)

```
feat: 수소 재고 카드 추가
fix: TT 교체 감지 후 3분 쿨다운 추가
refactor: 홈 화면 위젯 책임 분리
chore: 의존성 업데이트
```

- 제목 50자 이내, 명사형 종결
- 본문은 한 줄 띄고 **"왜"** 변경했는지. 재현 조건·수치를 남긴다
- **`Co-Authored-By` 넣지 않음. AI 이름 넣지 않음.**

### 브랜치

```
feat/stock-card
fix/tt-swap-detection
refactor/home-widgets
```

---

## Dart / Flutter

### 금지 항목

- `dynamic` — 절대 금지. `Object?`로 받고 타입 체크로 좁힘
- `as` 타입 단언 — 최후의 수단. `is` 체크 또는 제네릭으로 해결
- `!` null 단언 — 금지. `?.` / `??` / 早期 return 사용
- `late` — 초기화 순서가 자명한 경우만. 기본은 nullable
- `print` — `debugPrint`도 커밋 금지
- `build()` 안에서 API 호출·무거운 계산·`setState`
- 매직 넘버 (색·크기·간격) → 반드시 토큰 참조

### 불가능한 상태는 타입으로 차단한다

```dart
// Bad — 로딩 중인데 데이터가 있고 에러도 있는 조합이 가능
class HomeState {
  bool isLoading;
  IntegratedStatus? status;
  String? error;
}

// Good — 불가능한 조합이 타입 레벨에서 막힘
sealed class HomeState {
  const HomeState();
}
class HomeLoading extends HomeState {
  const HomeLoading();
}
class HomeReady extends HomeState {
  final IntegratedStatus status;
  const HomeReady(this.status);
}
class HomeFailed extends HomeState {
  final ApiException error;
  const HomeFailed(this.error);
}
```

`switch`로 소비하면 케이스 누락이 컴파일 에러가 된다.

### enum은 동작을 갖게 한다

값만 나열하고 호출부에서 `switch`를 반복하지 말 것. 표시 문자열·색은 enum 안에 둔다.

```dart
enum ChargerStatus {
  operating, broken, maintenance;

  String get displayName => switch (this) {
    ChargerStatus.operating => '정상',
    ChargerStatus.broken => '고장',
    ChargerStatus.maintenance => '점검중',
  };

  bool get isNormal => this == ChargerStatus.operating;
}
```

### 위젯

- **`StatelessWidget` 우선.** 상태가 정말 필요할 때만 `StatefulWidget`
- `const` 생성자를 최대한 붙인다 (리빌드 비용 절감)
- **줄 수가 아닌 책임 단위로 분리.** 50줄도 역할이 둘이면 분리, 단일 역할이면 200줄도 OK. 300줄 넘으면 검토
- 위젯 안에서 직접 API 호출·비즈니스 계산 금지 → `services/` · `providers/`로
- 파일당 public 위젯 하나. 내부 헬퍼 위젯은 허용
- 헬퍼는 `Widget _buildXxx()` 메서드보다 **별도 위젯 클래스**로 (const 최적화가 먹는다)

### 폴더 구조

```
lib/
├── main.dart
├── constants/
│   ├── colors.dart        # 컬러 토큰
│   ├── typography.dart    # 타입 스케일
│   ├── spacing.dart       # 간격 · 라운드 · 모션
│   └── strings.dart       # UI 문자열
├── screens/
│   ├── home/              # 손님 화면 (한 장)
│   ├── faq/
│   └── admin/             # 직원 화면
├── providers/
├── services/
└── widgets/               # 화면 공용 위젯
```

---

## 디자인 시스템 (★ 중요)

### 원칙 다섯

**① 오렌지는 "지금 봐야 하는 것"에만 붙는다.**
브랜드 장식으로 쓰지 않는다. 평소 손님 화면에서 오렌지는 **대기시간 숫자 하나뿐**이다.

**② 색은 강도를 만들지 않는다. 강도는 형태가 만든다.**

| 강도 | 수단 | 예 |
|---|---|---|
| 최강 | 모달 다이얼로그 | 영업 종료 |
| 강 | 배너 (히어로 위) | 충전기 고장 · 공지 |
| 중 | 카드 배경 틴트 | 마지막 T/T |
| 약 | 글씨 색 | 강조 텍스트 |

오렌지는 네 단계에 **똑같이** 쓰인다. 얼마나 급한지는 모달인지 배너인지가 말한다.

**③ 아무도 안 물어보는 정상 상태는 숨긴다.**
충전기·세차장이 정상이면 화면에 없다. 이상할 때만 나타난다.
단, **손님이 습관적으로 확인하는 항목**(잔압)은 정상이어도 상시 노출한다. 숨기면 다른 앱을 켜게 된다.

**④ 결론을 크게, 근거를 작게.**
`약 7분 기다려요`(54px)가 결론, `승용 2대 · 버스 1대`(12.5px)가 근거.
손님이 해독해야 하는 중간 데이터(`3대 중 2번째`)는 화면에 두지 않는다.

**④-1 관리 화면은 배치 기준이 다르다.**
손님 화면이 "볼 이유 없으면 뺀다"라면, 관리 화면은 **"안 보면 손해가 큰 순서"**로 쌓는다.

```
이상 지표    임계 넘으면 카드로       평균 잔압 65 · 손실률 ±2%
업무         하루 흐름 순             T/T(아침) → 매출 추이(16시) → 마감(퇴근 전)
T/T          내부 관리                손님 화면에 안 나감
충전소        손님 화면에 나가는 것들    충전기 · 세차장 · 공지
```

항목마다 **현재 값을 얹는다.** 눌러야 아는 버튼은 관리 도구가 아니다.
`›`는 화면·모달이 뜨는 것에만 쓰고, 값을 바꾸는 자리엔 토글을 둔다.

**⑤ 위치는 고정, 강조만 변한다.**
설치자가 100% 재방문자라 위치 학습이 이 앱의 자산이다.
상태에 따라 카드 순서를 바꾸지 않는다. **색과 배경만 바뀐다.**
시선은 위에서 아래로만 흐르지 않고 대비가 강한 곳으로 먼저 간다 — 색이면 충분하다.

### 컬러 토큰 — 8개가 전부

```dart
// lib/constants/colors.dart
abstract final class AppColors {
  // 브랜드 — E1 CI 규정 (Pantone 1665C · CMYK C0 M72 Y100 K3)
  static const orange     = Color(0xFFE96220); // 3.37:1 — 18px 이상 굵은 글씨만
  static const orangeText = Color(0xFFBA4A12); // 5.15:1 — 작은 글씨
  static const orangeTint = Color(0xFFFDEFE9); // 배너 · 경고 카드 배경

  // 중립
  static const gray900 = Color(0xFF30313A);    // 12.91:1 본문 · 히어로 숫자
  static const gray600 = Color(0xFF6B6C77);    //  5.31:1 보조 · 캡션
  static const gray300 = Color(0xFFD6D7DC);    // 구분선
  static const gray100 = Color(0xFFF3F3F3);    // 배경 (E1 Light Gray)
  static const card    = Color(0xFFFFFFFF);
}
```

```dart
// 관리 화면 T/T 상태색 — 이 화면, 이 카드에서만 쓴다
static const stateInUse = orangeText;         // 사용 중  5.15:1
static const stateReady = Color(0xFF1E7E3C);  // 대기     5.12:1
static const stateEmpty = gray600;            // 빈통     5.20:1
```

> **왜 관리 화면만 예외인가**
> 손님 화면에서 초록을 죽인 이유는 "정상이 하루의 대부분이라 초록이 상시 켜져
> 있어서"다. T/T는 3상태가 실제로 계속 돌기 때문에 그 문제가 없다.
> 그리고 관리 화면은 **조회가 목적**이라 전주의적 구분에 실질 가치가 있다.
> 셋 다 대비를 5.1~5.2:1로 맞춰 하나가 실수로 더 강조되지 않게 했다.
> **이 예외를 다른 화면·다른 항목으로 넓히지 말 것.**

**폐기됨. 되살리지 말 것:**
`#4CAF50` `#E57373` `#FFA726` `#E53935` `#A7C3E2` `#FFA987`,
`Colors.green` `Colors.red` `Colors.grey` `Colors.white`,
그리고 **`withOpacity()`로 회색 만들기**.

> 초록을 없앤 이유: 정상이 하루의 대부분이라 초록이 상시 켜져 있었다. 늘 켜진 신호는 신호가 아니다.
> 빨강을 없앤 이유: 이 앱엔 진짜 위험 상태가 없다. 충전기 고장도 "불편"이지 "위험"이 아니다.
> 덤으로 적록 구분 문제와 주황-빨강 인접(20° vs 3°) 문제가 함께 사라졌다.

#### 색 사용 규칙

- `orange`는 **18px 이상 굵은 글씨**에만. 그보다 작으면 `orangeText`
- 아이콘은 크기와 무관하게 `orange` 허용 (형태로 읽히므로)
- 상태를 색으로만 표현하지 않는다. **아이콘 + 텍스트를 반드시 동반**한다

### 타이포 스케일

```dart
// lib/constants/typography.dart
abstract final class AppText {
  static const display = TextStyle(fontSize: 54, fontWeight: FontWeight.w800, letterSpacing: -1.4, height: 1.0);
  static const h1      = TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6);
  static const h2      = TextStyle(fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -0.2);
  static const h3      = TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700);
  static const body    = TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500);
  static const small   = TextStyle(fontSize: 12.5);
  static const label   = TextStyle(fontSize: 11.5);
}
```

- 스케일에 없는 크기를 즉석에서 쓰지 않는다
- **숫자가 갱신되는 곳은 `FontFeature.tabularFigures()`** — 15초마다 바뀌는데 폭이 흔들리면 화면이 떨린다

#### 서체 역할 분담

- **Badasseugi (손글씨)** — 앱이 손님에게 *말을 거는* 부분에만. 제목, `지금 오시면`, `분 기다려요`
- **시스템 서체** — 숫자와 데이터 전부. 손글씨 숫자는 야외 가독성이 떨어진다

손글씨가 말을 걸고, 숫자는 또렷하게 읽힌다. 섞지 말 것.

### 간격 · 라운드 · 모션

```dart
// lib/constants/spacing.dart
abstract final class AppSpace {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 20.0, xxl = 24.0;
}

abstract final class AppRadius {
  static const card = 20.0, banner = 14.0, chip = 12.0, pill = 999.0;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);   // 색 · 투명도
  static const base = Duration(milliseconds: 220);   // 카드 등장 · 배너
  static const curve = Curves.easeOutCubic;
}
```

### 애니메이션 — 상태 변화만, 진입은 없음

**매일 여는 앱이다. 진입 애니메이션은 매일 겪는 지연이 된다.**

허용:
- 배너가 나타나고 사라질 때 — `AnimatedSize` + fade, `AppMotion.base`
- 카드가 정상↔경고로 물들 때 — `AnimatedContainer`, `AppMotion.fast`
- 스켈레톤 → 실제 데이터 — cross-fade, `AppMotion.base`

금지:
- 앱/화면 진입 시 순차 등장(staggered) 연출
- 숫자 카운트업 — 15초마다 갱신되는데 매번 굴러가면 읽을 수 없다. 값은 즉시 바꾸고 **주변 색만** 짧게 강조
- 스크롤 연동 패럴랙스, 로티, 장식용 루프 애니메이션

**`MediaQuery.disableAnimationsOf(context)`가 true면 전부 끈다.**

```dart
final reduced = MediaQuery.disableAnimationsOf(context);
final duration = reduced ? Duration.zero : AppMotion.base;
```

### 접근성

- **터치 타깃 48×48 이상.** `GestureDetector`에 아이콘만 넣지 말고 `padding`으로 넓힌다
  ```dart
  // Bad — 15px 아이콘이 곧 터치 영역
  GestureDetector(onTap: _x, child: Icon(LucideIcons.info, size: 15))

  // Good
  GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: _x,
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Icon(LucideIcons.info, size: 16),
    ),
  )
  ```
- **본문 대비 4.5:1, 18px 이상 굵은 글씨 3:1.** 토큰이 이미 이를 만족하므로 토큰 밖 색을 쓰지 않으면 지켜진다
- **옥외에서 읽힌다.** 햇빛 아래를 가정할 것. 밝은 색 위 밝은 글씨 금지
- 의미 있는 아이콘엔 `Semantics(label: ...)`
- 색만으로 상태를 전달하지 않는다 (원칙 ③ 참조)
- 시스템 글꼴 확대를 존중한다. 고정 높이 컨테이너에 텍스트를 가두지 말 것

---

## 도메인 규칙 (★ 중요)

현장에서 검증된 규칙. 임의로 바꾸지 말 것.

### 잔압을 잔량 게이지로 환산하지 않는다

T/T 교체 직후 잔압은 **180~190에서 시작**하고 **55~70에서 마감**한다. 양쪽 다 매번 다르다.
고정 구간(예: 185→55)으로 채움률을 계산하면:

- 실제로 70에서 끝나는 날 → "아직 11% 남음"으로 표시
- 190에서 시작한 날 → 채움률 100% 초과

**"조금 남았네" 보고 출발 → 도착하니 마감**은 이 앱에서 비용이 가장 큰 실패다.
잔압은 **숫자로만** 보여준다. 프로그레스 바·게이지·도넛 금지.

### 대기시간은 추정이다

`estimatedWaitMinutes`는 충전기 잔여시간 추적 + 진입/퇴출 감지로 보정한 값이지만 틀릴 수 있다.
**표시할 때 반드시 "약"을 붙인다.** 별도 면책 문구·토스트는 두지 않는다 — "약" 한 단어로 충분하다.

### `waitingCars` / `waitingBuses`는 대기줄이 아니다

**충전 중인 차량을 포함한 현황**이다. 대기시간 계산은 충전 중 차량을 제외하고 하므로 숫자와 시간이 단순 비례하지 않는다.

- 금지: `앞에 승용 2대` (2대를 다 기다린다는 뜻이 된다)
- 사용: `승용 2대 · 버스 1대`

### 상태는 2상태 토글로 바꾼다. 3상태 순환 금지

충전기(`정상`/`고장`)와 세차장(`운영`/`중단`)은 두 상태만 쓴다.
`maintenance` · `closed` enum은 과거 데이터 파싱을 위해 남겨두되 UI에서 쓰지 않는다.

3상태 순환이 금지인 이유: `점검중`에 닿으려면 `고장`을 거쳐야 하고,
**그 중간값이 서버에 저장되면서 손님 화면에 나간다.**
2상태면 잘못 눌러도 한 번 더 눌러 원복된다.

T/T의 `사용 중`은 백엔드가 잔압으로 자동 판정하므로 **토글을 아예 보여주지 않는다.**
눌러도 반응이 없으면 고장으로 오해한다.

### 충전기 A/B는 손님에게 노출하지 않는다

어느 충전기로 갈지는 직원이 안내한다. 손님 행동이 바뀌지 않는 정보다.

- 금지: `충전기 B 고장`
- 사용: `충전기 2기 중 1기 고장` — 대기가 왜 긴지가 바로 읽힌다

직원 화면에서는 A/B를 그대로 쓴다.

### T/T 순번은 손님에게 노출하지 않는다

`3대 중 2번째`는 손님이 해독해야 하는 중간 데이터다. 필요한 건 **마지막인가 아닌가**뿐.

- 손님: `오늘 T/T — 여유있어요` / `이게 마지막이에요`
- 직원: 차수·시각·상태 전부 노출

### 마감 임계값

잔압이 임계 아래로 내려가면 영업을 마친다. **매직 넘버로 흩뿌리지 말고 상수 하나로 관리한다.**

```dart
const kClosingPressureBar = 55;
```

---

## 상태 관리

| 종류 | 도구 | 용도 |
|---|---|---|
| 서버 상태 | `provider` + 폴링 | 충전소 현황 (15초) |
| 관리자 세션 | `provider` + `flutter_secure_storage` | 로그인 · 권한 |
| 로컬 설정 | `shared_preferences` | 팝업 노출 여부 등 |

- 위젯이 직접 `Dio`를 만지지 않는다 → `services/api/api_client.dart` 경유
- 폴링 타이머는 `dispose()`에서 반드시 취소
- 화면이 백그라운드일 때 폴링을 멈춘다 (`AppLifecycleState`)

---

## 에러 처리

- 네트워크 실패 시 **직전 값을 유지**한다. 화면을 비우지 않는다 (옥외에서 전파가 끊긴다)
- 사용자에게 보이는 메시지는 한국어, 기술 용어 금지
  - `DioException` ❌ → `잠시 후 다시 확인해 주세요.` ✅
- 값이 없을 때 `operating` 같은 안전값으로 조용히 떨어뜨리지 말 것 — 장애가 정상으로 보인다

---

## 네이밍

| 대상 | 규칙 | 예시 |
|---|---|---|
| 파일/폴더 | snake_case | `stock_card.dart` |
| 클래스/위젯 | PascalCase | `StockCard`, `WaitBanner` |
| 함수/변수 | camelCase | `fetchStatus`, `isOperating` |
| 상수 | k + PascalCase | `kClosingPressureBar` |
| private | `_` 접두사 | `_apiTimer` |
| boolean | is/has/can/should | `isLastTT`, `hasAlert` |
| 콜백 파라미터 | on + 명사 | `onTap`, `onRetry` |

---

## 테스트 (최소선)

**틀리면 손님이 헛걸음하는 곳만 골라 테스트한다.**

### 필수
- 대기시간 표시 로직 — 0분 / null / 영업종료 분기
- 마지막 T/T 판정 — `currentIndex == totalCount` 경계
- `ChargerStatus` · `TTStatus` 파싱 — 알 수 없는 값이 왔을 때

### 선택
- 위젯 테스트는 만들지 않는다. UI는 손으로 검증

### 실행
```
flutter test
flutter analyze
```

---

## 금지 사항 (요약)

- `dynamic` / `as` 캐스팅 / `!` null 단언
- `print` · `debugPrint` 커밋
- 하드코딩된 색·크기·간격·문자열
- `withOpacity()`로 회색 만들기 → `gray600` / `gray300` 사용
- 폐기된 색 되살리기 (초록·빨강·주황·피치)
- 색만으로 상태 전달
- 48×48 미만 터치 타깃
- 잔압 게이지 · 프로그레스 바
- 대기시간을 "약" 없이 표시
- `앞에 N대` 표현
- 손님 화면에 충전기 A/B · T/T 순번 노출
- 진입 애니메이션 · 숫자 카운트업
- 상태에 따라 카드 **순서** 바꾸기
- `build()` 안에서 API 호출 · `setState`
- 주석 처리된 코드 커밋 · 미사용 import · `// TODO` 방치
- `Co-Authored-By` 커밋 메시지

---

## PR / 작업 체크리스트

- [ ] `flutter analyze` 통과
- [ ] `dynamic` / `as` / `!` 사용 없음
- [ ] 색·크기·간격이 전부 토큰 참조
- [ ] 새로 추가한 색 없음 (8개 토큰 안에서 해결)
- [ ] 상태를 아이콘 + 텍스트로도 표현
- [ ] 터치 타깃 48×48 이상
- [ ] 숫자 갱신부에 `tabularFigures`
- [ ] `disableAnimationsOf` 존중
- [ ] 네트워크 실패 시 직전 값 유지
- [ ] 도메인 규칙 위반 없음 (잔압 게이지 · "약" · A/B 노출 · 순번 노출)
- [ ] 커밋 메시지에 **왜**가 있음
