import { Controller, Get } from '@nestjs/common';
import { HydrogenService, StationStatus } from './hydrogen.service';
import { StationService } from '../station/station.service';
import { TTService } from '../tt/tt.service';
import { RecordsService } from '../records/records.service';

@Controller()
export class HydrogenController {
  constructor(
    private readonly hydrogenService: HydrogenService,
    private readonly stationService: StationService,
    private readonly ttService: TTService,
    private readonly recordsService: RecordsService,
  ) {}

  // 공공 API 데이터만
  @Get('public')
  getPublicStatus(): StationStatus | { error: string } {
    const status = this.hydrogenService.getStationStatus();
    if (!status) {
      return { error: '데이터를 불러오는 중입니다' };
    }
    return status;
  }

  // 통합 응답
  @Get('integrated')
  async getIntegratedStatus() {
    const publicData = this.hydrogenService.getStationStatus();
    const stationData = await this.stationService.getStatus();
    const ttData = await this.ttService.getTodayStatus();
    const tomorrowTT = await this.ttService.getTomorrowStatus();
    const mealData = await this.recordsService.getTodayMeal();
    const estimatedWaitMinutes = await this.hydrogenService.getEstimatedWaitTime();

    return {
      public: publicData
        ? {
            ttPressure: publicData.ttPressure,
            waitingVehicles: publicData.waitingVehicles,
            waitingCars: publicData.waitingCars,
            waitingBuses: publicData.waitingBuses,
            operationStatus: publicData.operationStatus,
            isOperating: publicData.isOperating,
            lastUpdated: publicData.lastUpdated,
            estimatedWaitMinutes,
          }
        : null,
      station: {
        chargerA: stationData.chargerA,
        chargerB: stationData.chargerB,
        carWashStatus: stationData.carWashStatus,
        ttAStatus: stationData.ttAStatus,
        ttBStatus: stationData.ttBStatus,
        announcement: stationData.announcement,
      },
      tt: {
        totalCount: ttData.totalCount,
        currentIndex: ttData.currentIndex,
        schedules: ttData.schedules,
      },
      tomorrowTT: {
        schedules: tomorrowTT.schedules,
      },
      meal: {
        lunch: null,  // 홈 화면 표시 비활성화 (임시)
        dinner: null,
      },
    };
  }
}
