import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { HttpService } from '@nestjs/axios';
import { Cron, CronExpression } from '@nestjs/schedule';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';
import { TTService } from '../tt/tt.service';
import { StationService } from '../station/station.service';
import { RecordsService } from '../records/records.service';
import { ChargerStatus, TTStatus, ChargerTrackingEntity } from '../entities';
import { isBusinessHours, getKSTDate, getKSTTime } from '../common/utils/date.util';

// 충전 시간 상수 (분)
const CAR_CHARGE_TIME = 5;
const BUS_CHARGE_TIME = 30;

// 충전기 상태 타입
type ChargingType = 'car' | 'bus' | null;

interface ChargerState {
  type: ChargingType;
  startTime: Date | null;
}

export interface StationStatus {
  stationName: string;
  ttPressure: number | null;
  waitingVehicles: number | null;
  waitingCars: number | null;
  waitingBuses: number | null;
  operationStatus: string;
  lastUpdated: string | null;
  isOperating: boolean;
  cachedAt: string;
}

// H2nbiz API 응답 타입
interface H2nbizStationItem {
  chrstnMno: string;
  chrstnNm: string;
  waitVhcleAlgeCnt: string | number | null;
  waitCarAlgeCnt: string | number | null;
  waitBusAlgeCnt: string | number | null;
  operSttusNm: string;
}

@Injectable()
export class HydrogenService implements OnModuleInit {
  private readonly logger = new Logger(HydrogenService.name);
  private readonly h2nbizListUrl =
    'https://www.h2nbiz.or.kr/rt/sts/inf/getAjaxChrstnList.do';
  private readonly h2nbizEquipUrl =
    'https://www.h2nbiz.or.kr/rt/sts/inf/getRrtChrstnEqpSttusDLatestOne.do';
  private readonly targetStationCode = '4113320121HS2021030'; // 성남시 수소충전소

  private cachedStatus: StationStatus | null = null;

  // 대기시간 계산용 상태
  private prevCars: number | null = null;
  private prevBuses: number | null = null;

  // 충전기별 상태 추적 (후보정 방식)
  private chargerA: ChargerState = { type: null, startTime: null };
  private chargerB: ChargerState = { type: null, startTime: null };

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
    private readonly ttService: TTService,
    private readonly stationService: StationService,
    private readonly recordsService: RecordsService,
    @InjectRepository(ChargerTrackingEntity)
    private readonly trackingRepo: Repository<ChargerTrackingEntity>,
  ) {}

  async onModuleInit() {
    // 재시작으로 추적을 잃으면 대기시간이 "확인 중"으로 떨어진다. 먼저 복원한다.
    await this.restoreTracking();
    // 서버 시작 시 즉시 데이터 가져오기
    await this.fetchStationStatus();
  }

  @Cron('*/15 * * * * *')  // 15초마다
  async handleCron() {
    // 영업시간 체크 (KST 07:00~20:30만 API 호출)
    if (!this.isOperatingHours()) {
      return;
    }
    this.logger.log('Fetching station status (every 15 seconds)');
    await this.fetchStationStatus();
  }

  private isOperatingHours(): boolean {
    return isBusinessHours(7, 20, 30);
  }

  async fetchStationStatus(): Promise<void> {
    try {
      // 두 API 동시 호출
      const [listResponse, equipResponse] = await Promise.all([
        firstValueFrom(
          this.httpService.post(this.h2nbizListUrl, {}, {
            headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
          }),
        ),
        firstValueFrom(
          this.httpService.get(this.h2nbizEquipUrl, {
            params: { chrstnMno: this.targetStationCode, chrgrCd: '' },
          }),
        ),
      ]);

      // 충전소 목록에서 대기차량, 운영상태 가져오기
      const listData = listResponse.data?.data;
      if (!listData || !Array.isArray(listData)) {
        this.logger.warn('No data array in list response');
        return;
      }

      const station = listData.find(
        (item: H2nbizStationItem) => item.chrstnMno === this.targetStationCode,
      );

      if (!station) {
        this.logger.warn(`Station not found: ${this.targetStationCode}`);
        return;
      }

      this.logger.log(`Found station: ${station.chrstnNm}`);

      // 장비 상태에서 잔압 가져오기
      const equipData = equipResponse.data;
      const ttPressure = equipData?.ttPressr
        ? Math.floor(equipData.ttPressr / 10)
        : null;

      const waitingVehicles = this.parseNumber(station.waitVhcleAlgeCnt);
      const waitingCars = this.parseNumber(station.waitCarAlgeCnt);
      const waitingBuses = this.parseNumber(station.waitBusAlgeCnt);

      // waitVhcleAlge가 "영업마감"이면 그걸 사용, 아니면 operSttusNm 사용
      const waitVhcleAlge = station.waitVhcleAlge;
      const operationStatus = waitVhcleAlge === '영업마감'
        ? '영업마감'
        : (station.operSttusNm ?? '정보없음');

      this.cachedStatus = {
        stationName: station.chrstnNm,
        ttPressure,
        waitingVehicles,
        waitingCars,
        waitingBuses,
        operationStatus,
        lastUpdated: station.lastMdfcnDt ?? null,
        isOperating: operationStatus === '영업중',
        cachedAt: new Date().toISOString(),
      };

      // T/T 교체 감지 (잔압 +70 이상 급상승 시 자동 교체)
      if (ttPressure !== null) {
        const { changed, pressureBefore } = await this.ttService.checkPressureJump(ttPressure);

        if (changed && pressureBefore !== null) {
          // 자동 상태 스왑
          await this.autoTTChange(pressureBefore);
        }
      }

      // 대기시간 추적: 후보정
      await this.updateWaitTimeTracking(waitingCars, waitingBuses);

      // 추적 스냅샷 저장 — 배포·재시작이 상태를 지우지 않게
      await this.persistTracking();

      this.logger.log(
        `Cached: pressure=${ttPressure}, cars=${waitingCars}, buses=${waitingBuses}, status=${operationStatus}`,
      );
    } catch (error) {
      this.logger.error(`Error fetching station status: ${error.message}`);
    }
  }

  /**
   * 대기시간 추적: 후보정 방식
   *
   * - 승용 나감 → 승용 충전하던 충전기 비움, 대기열에서 새 차 들어감
   * - 버스 나감 → 버스 충전하던 충전기 비움, 대기열에서 새 차 들어감
   * - 0,0 상태 → 충전기 상태 리셋
   */
  private async updateWaitTimeTracking(
    currentCars: number | null,
    currentBuses: number | null,
  ): Promise<void> {
    const now = new Date();
    const cars = currentCars ?? 0;
    const buses = currentBuses ?? 0;
    const total = cars + buses;

    const avail = await this.getChargerAvailability();
    const availableChargers = this.chargerAvailableCount(avail);

    // 점검/고장 충전기 상태 강제 리셋
    if (!avail.a) this.chargerA = { type: null, startTime: null };
    if (!avail.b) this.chargerB = { type: null, startTime: null };

    // 0, 0 상태: 충전기 비움
    if (total === 0) {
      this.chargerA = { type: null, startTime: null };
      this.chargerB = { type: null, startTime: null };
      this.prevCars = 0;
      this.prevBuses = 0;
      this.logger.log('Station empty: reset charger states');
      return;
    }

    // 초기 상태
    if (this.prevCars === null || this.prevBuses === null) {
      this.prevCars = cars;
      this.prevBuses = buses;

      // 초기 상태에서도 현재 대기 중인 차량을 충전기에 배치
      let remainingCars = cars;
      let remainingBuses = buses;

      // 충전기 A 배치
      if (avail.a && (remainingCars > 0 || remainingBuses > 0)) {
        if (remainingBuses > 0) {
          this.chargerA = { type: 'bus', startTime: now };
          remainingBuses--;
        } else {
          this.chargerA = { type: 'car', startTime: now };
          remainingCars--;
        }
      }

      // 충전기 B 배치
      if (avail.b && (remainingCars > 0 || remainingBuses > 0)) {
        if (remainingBuses > 0) {
          this.chargerB = { type: 'bus', startTime: now };
        } else {
          this.chargerB = { type: 'car', startTime: now };
        }
      }

      this.logger.log(`Initial state: chargerA=${this.chargerA.type}, chargerB=${this.chargerB.type}`);
      return;
    }
    const prevTotal = this.prevCars + this.prevBuses;

    // 승용/버스 각각 변동 체크
    const carsExitedCount = Math.max(0, this.prevCars - cars);
    const busesExitedCount = Math.max(0, this.prevBuses - buses);
    const carsEnteredCount = Math.max(0, cars - this.prevCars);
    const busesEnteredCount = Math.max(0, buses - this.prevBuses);

    // 차량이 빠진 경우: 후보정 (해당 타입 충전기 비움)
    for (let i = 0; i < carsExitedCount; i++) {
      this.handleVehicleExit('car', now, cars, buses, avail);
    }
    for (let i = 0; i < busesExitedCount; i++) {
      this.handleVehicleExit('bus', now, cars, buses, avail);
    }

    // 차량이 들어온 경우: 빈 충전기에 배치
    for (let i = 0; i < carsEnteredCount; i++) {
      this.handleVehicleEnter('car', now, avail);
    }
    for (let i = 0; i < busesEnteredCount; i++) {
      this.handleVehicleEnter('bus', now, avail);
    }

    // 충전기 차종 추적을 실제 대기 수와 대조하여 유령 상태 제거
    this.reconcileChargerTypes(cars, buses);

    // 빈 충전기 + 남은 대기열 = 추적 공백. 추정으로 메운다.
    this.backfillEmptyChargers(cars, buses, now, avail);

    this.prevCars = cars;
    this.prevBuses = buses;
  }

  /**
   * 추적 공백 메움: 충전기가 비었는데 대기 차량이 남아 있으면 추정 배치한다.
   *
   * 진입 때 충전기가 차 있으면 그 차는 추적 없이 대기열로 남는데, 이후
   * 자리가 나도(유령 제거·미감지 완료) 재배치하는 곳이 없어 "빈 충전기 +
   * 대기열"로 굳는 경로가 있었다. 이 상태가 대기시간 계산에서 기본값
   * 상수(승용 5분)로 새어 나가 5분에 고정돼 보였다. 현장에선 자리가 나면
   * 바로 물리므로, 추정 배치가 실제에 가깝다.
   */
  private backfillEmptyChargers(
    cars: number,
    buses: number,
    now: Date,
    avail: { a: boolean; b: boolean },
  ): void {
    if (avail.a && this.chargerA.type === null) {
      const next = this.estimateNextVehicle(now, cars, buses);
      if (next.type !== null) {
        this.chargerA = next;
        this.logger.log(`Backfill: charger A <- ${next.type}`);
      }
    }
    if (avail.b && this.chargerB.type === null) {
      const next = this.estimateNextVehicle(now, cars, buses);
      if (next.type !== null) {
        this.chargerB = next;
        this.logger.log(`Backfill: charger B <- ${next.type}`);
      }
    }
  }

  /** 10분 넘은 스냅샷은 버린다 — 그 사이 차들이 다 바뀌었을 것이다. */
  private static readonly TRACKING_MAX_AGE_MS = 10 * 60 * 1000;

  private async restoreTracking(): Promise<void> {
    try {
      const row = await this.trackingRepo.findOne({ where: { id: 1 } });
      if (!row) return;
      const age = Date.now() - row.updatedAt.getTime();
      if (age > HydrogenService.TRACKING_MAX_AGE_MS) {
        this.logger.log(`Tracking snapshot too old (${Math.round(age / 60000)}min), starting fresh`);
        return;
      }
      const revive = (c: { type: ChargingType; startTime: string | null }): ChargerState => ({
        type: c.type,
        startTime: c.startTime ? new Date(c.startTime) : null,
      });
      this.chargerA = revive(row.state.chargerA);
      this.chargerB = revive(row.state.chargerB);
      this.prevCars = row.state.prevCars;
      this.prevBuses = row.state.prevBuses;
      this.logger.log(
        `Tracking restored: A=${this.chargerA.type}, B=${this.chargerB.type} (${Math.round(age / 1000)}s old)`,
      );
    } catch (error) {
      // 복원 실패 = 재시작 직후와 같은 상태. 앱은 "확인 중"으로 넘어가고 폴링이 메운다.
      this.logger.warn(`Tracking restore failed: ${error.message}`);
    }
  }

  private async persistTracking(): Promise<void> {
    try {
      const dump = (c: ChargerState) => ({
        type: c.type,
        startTime: c.startTime ? c.startTime.toISOString() : null,
      });
      await this.trackingRepo.save({
        id: 1,
        state: {
          chargerA: dump(this.chargerA),
          chargerB: dump(this.chargerB),
          prevCars: this.prevCars,
          prevBuses: this.prevBuses,
        },
      });
    } catch (error) {
      // 저장 실패로 본 기능을 막지 않는다. 다음 폴링에 다시 시도된다.
      this.logger.warn(`Tracking persist failed: ${error.message}`);
    }
  }

  /**
   * 충전기 차종 추적을 실제 대기 수와 대조 (자가 교정)
   *
   * 모델상 cars/buses는 "충전 중 + 대기 중" 총합이므로,
   * 특정 차종으로 잡힌 충전기 개수가 그 차종의 총수를 넘을 수 없다.
   * 넘으면 과거 추적의 잔재(유령)이므로 초과분을 비운다.
   * (예: 버스가 70% 미만에서 빠져 handleVehicleExit가 충전기를 유지한 경우,
   *  buses=0이 되면 여기서 유령 버스가 제거됨)
   */
  private reconcileChargerTypes(cars: number, buses: number): void {
    this.capChargerType('bus', buses);
    this.capChargerType('car', cars);
  }

  private capChargerType(type: 'car' | 'bus', maxCount: number): void {
    const matches: { label: 'A' | 'B'; startTime: Date | null }[] = [];
    if (this.chargerA.type === type) {
      matches.push({ label: 'A', startTime: this.chargerA.startTime });
    }
    if (this.chargerB.type === type) {
      matches.push({ label: 'B', startTime: this.chargerB.startTime });
    }
    if (matches.length <= maxCount) return;

    // 오래된(startTime 빠른) 것부터 비움 → 유령(stale) 우선 제거
    matches.sort(
      (a, b) => (a.startTime?.getTime() ?? 0) - (b.startTime?.getTime() ?? 0),
    );
    const clearCount = matches.length - maxCount;
    for (let i = 0; i < clearCount; i++) {
      const label = matches[i].label;
      if (label === 'A') this.chargerA = { type: null, startTime: null };
      else this.chargerB = { type: null, startTime: null };
      this.logger.log(
        `Reconcile: cleared phantom ${type} on charger ${label} (tracked ${matches.length} > actual ${maxCount})`,
      );
    }
  }

  /**
   * 충전기의 경과 비율 계산 (충전 완료에 얼마나 가까운지)
   */
  private getElapsedRatio(charger: ChargerState, now: Date): number {
    if (charger.type === null || charger.startTime === null) return 0;
    const chargeTime = charger.type === 'car' ? CAR_CHARGE_TIME : BUS_CHARGE_TIME;
    const elapsedMinutes = (now.getTime() - charger.startTime.getTime()) / 60000;
    return elapsedMinutes / chargeTime;
  }

  /**
   * 차량 나감 처리
   * - 경과시간 >= 70%: 충전 완료로 판단 → 충전기 리셋, 다음 차 배치
   * - 경과시간 < 70%: 대기열에서 빠진 것으로 판단 → 충전기 안 건드림
   */
  private handleVehicleExit(
    exitType: 'car' | 'bus',
    now: Date,
    remainingCars: number,
    remainingBuses: number,
    avail: { a: boolean; b: boolean },
  ): void {
    const COMPLETION_THRESHOLD = 0.7;

    // 해당 타입 충전하던 가용 충전기 찾기
    const chargerAMatch = avail.a && this.chargerA.type === exitType;
    const chargerBMatch = avail.b && this.chargerB.type === exitType;

    if (chargerAMatch || chargerBMatch) {
      // 매칭되는 충전기의 경과 비율 확인
      const target = chargerAMatch ? this.chargerA : this.chargerB;
      const ratio = this.getElapsedRatio(target, now);

      if (ratio >= COMPLETION_THRESHOLD) {
        // 충전 완료: 충전기 비우고 다음 차 배치
        const label = chargerAMatch ? 'A' : 'B';
        this.logger.log(`Charger ${label}: ${exitType} finished (${Math.round(ratio * 100)}% elapsed)`);
        if (chargerAMatch) {
          this.chargerA = { type: null, startTime: null };
          this.chargerA = this.estimateNextVehicle(now, remainingCars, remainingBuses);
        } else {
          this.chargerB = { type: null, startTime: null };
          this.chargerB = this.estimateNextVehicle(now, remainingCars, remainingBuses);
        }
      } else {
        // 대기열에서 빠진 것으로 판단: 충전기 안 건드림
        this.logger.log(`Queue ${exitType} left (charger only ${Math.round(ratio * 100)}% elapsed, keeping)`);
      }
    } else {
      // 충전기에 해당 타입 없음 → 대기열에서 빠진 것
      this.logger.log(`Queue ${exitType} left (not on any charger)`);
    }
  }

  /**
   * 차량 들어옴 처리: 가용 충전기에 배치
   */
  private handleVehicleEnter(
    enterType: 'car' | 'bus',
    now: Date,
    avail: { a: boolean; b: boolean },
  ): void {
    // 가용한 빈 충전기에만 배치
    if (avail.a && this.chargerA.type === null) {
      this.chargerA = { type: enterType, startTime: now };
      this.logger.log(`Charger A: ${enterType} entered`);
    } else if (avail.b && this.chargerB.type === null) {
      this.chargerB = { type: enterType, startTime: now };
      this.logger.log(`Charger B: ${enterType} entered`);
    }
    // 충전기 꽉 참 → 대기열에 추가 (추적 안 함)
  }

  /**
   * 대기열에서 다음 차 타입 추정 (비율 기반)
   */
  private estimateNextVehicle(
    now: Date,
    remainingCars: number,
    remainingBuses: number,
  ): ChargerState {
    const total = remainingCars + remainingBuses;
    if (total === 0) {
      return { type: null, startTime: null };
    }

    // 현재 충전기에 있는 타입 제외하고 대기열 추정
    let queueCars = remainingCars;
    let queueBuses = remainingBuses;

    if (this.chargerA.type === 'car') queueCars = Math.max(0, queueCars - 1);
    if (this.chargerA.type === 'bus') queueBuses = Math.max(0, queueBuses - 1);
    if (this.chargerB.type === 'car') queueCars = Math.max(0, queueCars - 1);
    if (this.chargerB.type === 'bus') queueBuses = Math.max(0, queueBuses - 1);

    const queueTotal = queueCars + queueBuses;
    if (queueTotal === 0) {
      return { type: null, startTime: null };
    }

    // 비율로 추정: 승용이 더 많으면 승용, 버스가 더 많으면 버스
    const nextType: ChargingType = queueCars >= queueBuses ? 'car' : 'bus';
    this.logger.log(`Next vehicle estimated: ${nextType} (queue: cars=${queueCars}, buses=${queueBuses})`);
    return { type: nextType, startTime: now };
  }

  /**
   * 충전기별 가용 여부 확인
   */
  private async getChargerAvailability(): Promise<{ a: boolean; b: boolean }> {
    try {
      const status = await this.stationService.getStatus();
      return {
        a: status.chargerA === ChargerStatus.OPERATING,
        b: status.chargerB === ChargerStatus.OPERATING,
      };
    } catch {
      return { a: true, b: true }; // 기본값
    }
  }

  private chargerAvailableCount(avail: { a: boolean; b: boolean }): number {
    return (avail.a ? 1 : 0) + (avail.b ? 1 : 0);
  }

  /**
   * 충전기 남은 시간 계산
   */
  private getChargerRemainingTime(charger: ChargerState, now: Date): number | null {
    if (charger.type === null || charger.startTime === null) {
      return null; // 모르는 상태
    }

    const chargeTime = charger.type === 'car' ? CAR_CHARGE_TIME : BUS_CHARGE_TIME;
    const elapsedMinutes = (now.getTime() - charger.startTime.getTime()) / 60000;
    return Math.max(0, chargeTime - elapsedMinutes);
  }

  /**
   * 예상 대기시간 계산 (후보정 방식)
   * "내가 지금 가면 몇 분 기다려야 하나"를 계산
   * - 충전기 0대: null 반환 (앱에서 "-" 표시)
   * - 빈 충전기 있음: 0분
   * - 충전기별 남은 시간 + 대기열 시뮬레이션
   */
  async getEstimatedWaitTime(): Promise<number | null> {
    const now = new Date();
    const avail = await this.getChargerAvailability();
    const availableChargers = this.chargerAvailableCount(avail);
    const cars = this.cachedStatus?.waitingCars ?? 0;
    const buses = this.cachedStatus?.waitingBuses ?? 0;
    const totalWaiting = cars + buses;

    // 충전기 0대 (둘 다 고장/점검): null 반환
    if (availableChargers === 0) {
      return null;
    }

    // 대기 없음: 바로 충전 가능
    if (totalWaiting === 0) {
      return 0;
    }

    // 빈 충전기 있음: 바로 충전 가능
    if (totalWaiting < availableChargers) {
      return 0;
    }

    // 충전기별 남은 시간 계산 (가용 충전기만)
    const remainingA = avail.a ? this.getChargerRemainingTime(this.chargerA, now) : null;
    const remainingB = avail.b ? this.getChargerRemainingTime(this.chargerB, now) : null;

    // 추적을 모르는 충전기가 있으면 숫자를 만들지 않는다.
    // 기본값으로 채우면 "승용 5분" 상수가 실측처럼 찍힌다(실제로 5분 고정 표시 발생).
    // null은 앱에서 "확인 중"이 되고, 다음 폴링의 backfill이 15초 안에 공백을 메운다.
    if ((avail.a && remainingA === null) || (avail.b && remainingB === null)) {
      return null;
    }

    // 충전 중인 차량 파악 (가용 충전기만 — 위 가드로 타입이 전부 확정된 상태)
    let chargingCars = 0;
    let chargingBuses = 0;
    if (avail.a && this.chargerA.type === 'car') chargingCars++;
    if (avail.a && this.chargerA.type === 'bus') chargingBuses++;
    if (avail.b && this.chargerB.type === 'car') chargingCars++;
    if (avail.b && this.chargerB.type === 'bus') chargingBuses++;

    // 대기열: 전체에서 충전 중인 차량 제외
    const queuedCars = Math.max(0, cars - chargingCars);
    const queuedBuses = Math.max(0, buses - chargingBuses);

    // 대기열 배열 생성 (각 차량의 충전 시간)
    // 승용차 먼저, 버스 나중 (FIFO 가정)
    const queue: number[] = [];
    for (let i = 0; i < queuedCars; i++) queue.push(CAR_CHARGE_TIME);
    for (let i = 0; i < queuedBuses; i++) queue.push(BUS_CHARGE_TIME);
    // "나" 추가 (승용차로 가정)
    queue.push(CAR_CHARGE_TIME);

    // 충전기 남은 시간 배열 (가용 충전기만 — 전부 아는 값)
    const chargers: number[] = [];
    if (avail.a && remainingA !== null) chargers.push(remainingA);
    if (avail.b && remainingB !== null) chargers.push(remainingB);

    // 시뮬레이션: "나"가 충전기에 배치될 때까지
    let time = 0;
    while (queue.length > 0) {
      // 가장 빨리 끝나는 충전기 찾기
      const minRemaining = Math.min(...chargers);
      const minIndex = chargers.indexOf(minRemaining);

      // 시간 경과
      time += minRemaining;
      for (let i = 0; i < chargers.length; i++) {
        chargers[i] -= minRemaining;
      }

      // 다음 대기 차량 배치
      const nextVehicle = queue.shift()!;
      chargers[minIndex] = nextVehicle;

      // 마지막 대기 차량("나")이 배치되면 종료
      if (queue.length === 0) {
        return Math.round(time);
      }
    }

    return Math.round(time);
  }

  private parseNumber(value: string | number | null | undefined): number | null {
    if (value === null || value === undefined || value === '') {
      return null;
    }
    const num = typeof value === 'number' ? value : parseInt(value, 10);
    return isNaN(num) ? null : num;
  }

  getStationStatus(): StationStatus | null {
    return this.cachedStatus;
  }

  /**
   * T/T 자동 교체 처리
   * - 사용중 → 빈통
   * - 대기 → 사용중
   * - 잔압 저장
   */
  private async autoTTChange(pressureBefore: number): Promise<void> {
    try {
      const stationStatus = await this.stationService.getStatus();
      const ttAStatus = stationStatus.ttAStatus;
      const ttBStatus = stationStatus.ttBStatus;

      // 현재 사용중인 T/T 확인
      let direction: 'A>B' | 'B>A';
      if (ttAStatus === TTStatus.IN_USE && ttBStatus === TTStatus.STANDBY) {
        direction = 'A>B';
      } else if (ttBStatus === TTStatus.IN_USE && ttAStatus === TTStatus.STANDBY) {
        direction = 'B>A';
      } else if (ttAStatus === TTStatus.IN_USE && ttBStatus === TTStatus.EMPTY) {
        // 반대편이 빈통이면 대기로 변경 후 교체 (입고 누락 케이스)
        await this.stationService.setTTStatus(TTStatus.IN_USE, TTStatus.STANDBY);
        direction = 'A>B';
        this.logger.log('Auto T/T: B was EMPTY, changed to STANDBY');
      } else if (ttBStatus === TTStatus.IN_USE && ttAStatus === TTStatus.EMPTY) {
        // 반대편이 빈통이면 대기로 변경 후 교체 (입고 누락 케이스)
        await this.stationService.setTTStatus(TTStatus.STANDBY, TTStatus.IN_USE);
        direction = 'B>A';
        this.logger.log('Auto T/T: A was EMPTY, changed to STANDBY');
      } else {
        this.logger.warn('Auto T/T change skipped: invalid state');
        return;
      }

      // 상태 스왑
      const result = await this.stationService.ttChange({ direction, pressureBefore });
      if (!result.success) {
        this.logger.warn(`Auto T/T change failed: ${result.message}`);
        return;
      }

      // 잔압 저장
      const today = getKSTDate();
      await this.recordsService.addTTChange(today, {
        record: {
          time: getKSTTime(),
          direction,
          meterValue: 0,
          monthlyIndex: 0,
          pressureBefore,
        },
      });

      this.logger.log(`Auto T/T change: ${direction}, pressure: ${pressureBefore}`);
    } catch (error) {
      this.logger.error(`Auto T/T change error: ${error.message}`);
    }
  }

}
