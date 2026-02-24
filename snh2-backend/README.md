# 성남수소충전소 (snh2) Backend

성남수소충전소 앱의 백엔드 API 서버입니다.

<p align="center">
  <img src="https://img.shields.io/badge/NestJS-E0234E?style=for-the-badge&logo=nestjs&logoColor=white" />
  <img src="https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white" />
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" />
</p>

## 주요 기능

### 실시간 현황 조회

한국석유관리원 공공 API와 직원 입력 데이터를 통합하여 제공합니다.

- 대기차량 수 (승용/버스 구분)
- T/T 잔압 (bar)
- 충전기 A/B 상태 (정상/고장/점검)
- 세차장 운영 상태
- 예상 대기시간 자동 계산
- 15초마다 자동 갱신 (Cron)

### T/T 관리

- T/T 상태 변경 (빈통 → 대기 → 사용중)
- 입고 일정 관리 (당일/내일)
- 교체 기록 (방향, 잔압, 계량기값, 월별 순번)

### 매출 관리

- 일일 매출 입력 (kg, 대수, 유량계)
- 월별 통계 자동 계산
- 평균 잔압, 손실률 조회

### 업무일지

- 날짜별 T/T 입출고/교체 기록
- 특이사항 검색 (최근 1년)

### 기타

- 공지사항 등록
- 식사 메뉴 입력
- 건의사항 접수

## 기술 스택

| 분류 | 기술 |
|------|------|
| Framework | NestJS 11.x |
| Language | TypeScript 5.x |
| Database | PostgreSQL + TypeORM |
| Scheduling | @nestjs/schedule (Cron) |
| External API | 한국석유관리원 (하잉) |

## 프로젝트 구조

```
src/
├── entities/           # TypeORM 엔티티
│   ├── station-status.entity.ts
│   ├── tt-status.entity.ts
│   ├── daily-worklog.entity.ts
│   ├── sales-record.entity.ts
│   ├── daily-meal.entity.ts
│   ├── monthly-stats.entity.ts
│   └── suggestion.entity.ts
├── hydrogen/           # 공공 API 연동
├── station/            # 충전소 상태 관리
├── tt/                 # T/T 일정 관리
├── records/            # 매출, 업무일지
└── suggestion/         # 건의사항
```

## API 엔드포인트

### 통합 현황
- `GET /api/integrated` - 통합 현황 (공공API + 직원입력)
- `GET /api/public` - 공공 API 데이터만

### 충전소 관리
- `PATCH /api/station/charger` - 충전기 상태 변경
- `PATCH /api/station/carwash` - 세차장 상태 변경
- `PATCH /api/station/announcement` - 공지사항 업데이트
- `POST /api/station/tt/incoming` - T/T 입고
- `POST /api/station/tt/change` - T/T 교체

### T/T 일정
- `GET /api/tt/today` - 오늘 T/T 현황
- `PUT /api/tt/schedule` - T/T 일정 변경

### 매출/업무일지
- `GET /api/sales/:date` - 매출 조회
- `PUT /api/sales/:date` - 매출 입력
- `GET /api/sales/stats/monthly` - 월별 통계
- `GET /api/worklog/:date` - 업무일지 조회
- `GET /api/worklog/search` - 특이사항 검색

## 시작하기

```bash
# 의존성 설치
npm install

# 환경 변수 설정
cp .env.example .env

# 개발 서버 실행
npm run start:dev
```

## 환경 변수

```env
DATABASE_URL=postgresql://user:password@host:port/database
```

## 배포

Railway를 통해 자동 배포됩니다.

---

<p align="center">
  snh2-backend © 2025
</p>
