import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { Cron, CronExpression } from '@nestjs/schedule';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';
import { TTService } from '../tt/tt.service';
import { StationService } from '../station/station.service';
import { RecordsService } from '../records/records.service';
import { ChargerStatus, TTStatus } from '../entities';
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
  ) {}

  async onModuleInit() {
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
      const availableChargers = await this.getAvailableChargerCount();
      let remainingCars = cars;
      let remainingBuses = buses;

      // 충전기 A 배치
      if (availableChargers >= 1 && (remainingCars > 0 || remainingBuses > 0)) {
        if (remainingBuses > 0) {
          this.chargerA = { type: 'bus', startTime: now };
          remainingBuses--;
        } else {
          this.chargerA = { type: 'car', startTime: now };
          remainingCars--;
        }
      }

      // 충전기 B 배치
      if (availableChargers >= 2 && (remainingCars > 0 || remainingBuses > 0)) {
        if (remainingBuses > 0) {
          this.chargerB = { type: 'bus', startTime: now };
        } else {
          this.chargerB = { type: 'car', startTime: now };
        }
      }

      this.logger.log(`Initial state: chargerA=${this.chargerA.type}, chargerB=${this.chargerB.type}`);
      return;
    }

    const availableChargers = await this.getAvailableChargerCount();
    const prevTotal = this.prevCars + this.prevBuses;

    // 승용/버스 각각 변동 체크
    const carsExitedCount = Math.max(0, this.prevCars - cars);
    const busesExitedCount = Math.max(0, this.prevBuses - buses);
    const carsEnteredCount = Math.max(0, cars - this.prevCars);
    const busesEnteredCount = Math.max(0, buses - this.prevBuses);

    // 차량이 빠진 경우: 후보정 (해당 타입 충전기 비움)
    for (let i = 0; i < carsExitedCount; i++) {
      this.handleVehicleExit('car', now, cars, buses);
    }
    for (let i = 0; i < busesExitedCount; i++) {
      this.handleVehicleExit('bus', now, cars, buses);
    }

    // 차량이 들어온 경우: 빈 충전기에 배치
    for (let i = 0; i < carsEnteredCount; i++) {
      this.handleVehicleEnter('car', now, availableChargers);
    }
    for (let i = 0; i < busesEnteredCount; i++) {
      this.handleVehicleEnter('bus', now, availableChargers);
    }

    this.prevCars = cars;
    this.prevBuses = buses;
  }

  /**
   * 차량 나감 처리: 해당 타입 충전기 비우고, 대기열에서 새 차 들어감
   */
  private handleVehicleExit(
    exitType: 'car' | 'bus',
    now: Date,
    remainingCars: number,
    remainingBuses: number,
  ): void {
    // 해당 타입 충전하던 충전기 찾아서 비움
    if (this.chargerA.type === exitType) {
      this.logger.log(`Charger A: ${exitType} exited`);
      // 대기열에서 새 차 들어감 (비율로 추정)
      this.chargerA = this.estimateNextVehicle(now, remainingCars, remainingBuses);
    } else if (this.chargerB.type === exitType) {
      this.logger.log(`Charger B: ${exitType} exited`);
      this.chargerB = this.estimateNextVehicle(now, remainingCars, remainingBuses);
    } else {
      // 모르는 상태에서 나감 → 아무 충전기나 업데이트
      if (this.chargerA.type === null) {
        this.logger.log(`Charger A: ${exitType} exited (was unknown)`);
        this.chargerA = this.estimateNextVehicle(now, remainingCars, remainingBuses);
      } else if (this.chargerB.type === null) {
        this.logger.log(`Charger B: ${exitType} exited (was unknown)`);
        this.chargerB = this.estimateNextVehicle(now, remainingCars, remainingBuses);
      }
    }
  }

  /**
   * 차량 들어옴 처리: 빈 충전기에 배치
   */
  private handleVehicleEnter(
    enterType: 'car' | 'bus',
    now: Date,
    availableChargers: number,
  ): void {
    // 빈 충전기에 배치
    if (this.chargerA.type === null && availableChargers >= 1) {
      this.chargerA = { type: enterType, startTime: now };
      this.logger.log(`Charger A: ${enterType} entered`);
    } else if (this.chargerB.type === null && availableChargers >= 2) {
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
   * 가용 충전기 수 확인
   */
  private async getAvailableChargerCount(): Promise<number> {
    try {
      const status = await this.stationService.getStatus();
      let count = 0;
      if (status.chargerA === ChargerStatus.OPERATING) count++;
      if (status.chargerB === ChargerStatus.OPERATING) count++;
      return count;
    } catch {
      return 2; // 기본값
    }
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
    const availableChargers = await this.getAvailableChargerCount();
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

    // 충전기별 남은 시간 계산
    const remainingA = this.getChargerRemainingTime(this.chargerA, now);
    const remainingB = this.getChargerRemainingTime(this.chargerB, now);

    // 충전 중인 차량 파악
    let chargingCars = 0;
    let chargingBuses = 0;
    if (this.chargerA.type === 'car') chargingCars++;
    if (this.chargerA.type === 'bus') chargingBuses++;
    if (this.chargerB.type === 'car') chargingCars++;
    if (this.chargerB.type === 'bus') chargingBuses++;

    // 모르는 충전기 → 비율로 추정
    const unknownChargers = (this.chargerA.type === null ? 1 : 0) + (this.chargerB.type === null ? 1 : 0);
    if (unknownChargers > 0 && totalWaiting >= availableChargers) {
      const carRatio = cars / totalWaiting;
      const estimatedCars = Math.round(unknownChargers * carRatio);
      chargingCars += estimatedCars;
      chargingBuses += unknownChargers - estimatedCars;
    }

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

    // 충전기 남은 시간 배열 생성
    const chargers: number[] = [];
    if (availableChargers >= 1) {
      // remainingA가 null이면 타입에 따라 기본값 사용
      const defaultA = this.chargerA.type === 'bus' ? BUS_CHARGE_TIME : CAR_CHARGE_TIME;
      chargers.push(remainingA ?? defaultA);
    }
    if (availableChargers >= 2) {
      const defaultB = this.chargerB.type === 'bus' ? BUS_CHARGE_TIME : CAR_CHARGE_TIME;
      chargers.push(remainingB ?? defaultB);
    }

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
