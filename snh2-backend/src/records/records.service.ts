import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, Like, MoreThanOrEqual } from 'typeorm';
import { Cron } from '@nestjs/schedule';
import { DailyMealEntity, SalesRecordEntity, DailyWorklogEntity, TTInOutRecord, TTChangeRecord, MonthlyStatsEntity } from '../entities';
import { UpdateMealDto, UpdateSalesDto, MonthlySalesStatsDto, DailySalesDto } from './dto/records.dto';
import { AddTTInOutDto, AddTTChangeDto, UpdateWorklogNotesDto, UpdateWorklogDto, MonthlyPressureStatsDto, MonthlyLossStatsDto } from './dto/worklog.dto';

@Injectable()
export class RecordsService {
  private readonly logger = new Logger(RecordsService.name);

  constructor(
    @InjectRepository(DailyMealEntity)
    private readonly mealRepo: Repository<DailyMealEntity>,
    @InjectRepository(SalesRecordEntity)
    private readonly salesRepo: Repository<SalesRecordEntity>,
    @InjectRepository(DailyWorklogEntity)
    private readonly worklogRepo: Repository<DailyWorklogEntity>,
    @InjectRepository(MonthlyStatsEntity)
    private readonly monthlyStatsRepo: Repository<MonthlyStatsEntity>,
  ) {}

  // KST 00:00 = UTC 15:00
  @Cron('0 15 * * *')
  async resetDailyMeal() {
    this.logger.log('Resetting daily meal at KST 00:00');
    const meal = await this.getOrCreateMeal();
    meal.lunch = null;
    meal.dinner = null;
    await this.mealRepo.save(meal);
  }

  private getKSTDate(): string {
    const now = new Date();
    const kstOffset = 9 * 60; // KST = UTC+9
    const kstTime = new Date(now.getTime() + kstOffset * 60 * 1000);
    return kstTime.toISOString().split('T')[0];
  }

  // 단일 레코드 유지 (id=1)
  private async getOrCreateMeal(): Promise<DailyMealEntity> {
    let meal = await this.mealRepo.findOne({ where: { id: 1 } });
    if (!meal) {
      meal = await this.mealRepo.save({
        id: 1,
        date: this.getKSTDate(),
        lunch: null,
        dinner: null,
      });
    }
    return meal;
  }

  // Meal
  async getTodayMeal(): Promise<DailyMealEntity> {
    return this.getOrCreateMeal();
  }

  async updateTodayMeal(dto: UpdateMealDto): Promise<DailyMealEntity> {
    const meal = await this.getOrCreateMeal();

    if (dto.lunch !== undefined) {
      meal.lunch = dto.lunch;
    }
    if (dto.dinner !== undefined) {
      meal.dinner = dto.dinner;
    }

    // 업데이트할 때 날짜도 갱신
    meal.date = this.getKSTDate();

    return this.mealRepo.save(meal);
  }

  // Sales
  async getSalesByDate(date: string): Promise<SalesRecordEntity | null> {
    return this.salesRepo.findOne({ where: { date } });
  }

  async updateSales(date: string, dto: UpdateSalesDto): Promise<SalesRecordEntity> {
    let sales = await this.salesRepo.findOne({ where: { date } });

    if (!sales) {
      sales = this.salesRepo.create({ date });
    }

    if (dto.flowMeter !== undefined) {
      sales.flowMeter = dto.flowMeter;
    }
    sales.totalKg = dto.totalKg;
    sales.totalVehicles = dto.totalVehicles;

    return this.salesRepo.save(sales);
  }

  // Worklog
  private async getOrCreateWorklog(date: string): Promise<DailyWorklogEntity> {
    let worklog = await this.worklogRepo.findOne({ where: { date } });
    if (!worklog) {
      worklog = this.worklogRepo.create({
        date,
        ttInOutRecords: [],
        ttChangeRecords: [],
        notes: null,
      });
      worklog = await this.worklogRepo.save(worklog);
    }
    return worklog;
  }

  async getWorklogByDate(date: string): Promise<DailyWorklogEntity | null> {
    return this.worklogRepo.findOne({ where: { date } });
  }

  async getTodayWorklog(): Promise<DailyWorklogEntity> {
    const today = this.getKSTDate();
    return this.getOrCreateWorklog(today);
  }

  async addTTInOut(date: string, dto: AddTTInOutDto): Promise<DailyWorklogEntity> {
    const worklog = await this.getOrCreateWorklog(date);

    if (!worklog.ttInOutRecords) {
      worklog.ttInOutRecords = [];
    }

    worklog.ttInOutRecords.push(dto.record);
    return this.worklogRepo.save(worklog);
  }

  async addTTChange(date: string, dto: AddTTChangeDto): Promise<DailyWorklogEntity> {
    const worklog = await this.getOrCreateWorklog(date);

    if (!worklog.ttChangeRecords) {
      worklog.ttChangeRecords = [];
    }

    worklog.ttChangeRecords.push(dto.record);
    return this.worklogRepo.save(worklog);
  }

  async updateWorklogNotes(date: string, dto: UpdateWorklogNotesDto): Promise<DailyWorklogEntity> {
    const worklog = await this.getOrCreateWorklog(date);
    worklog.notes = dto.notes;
    return this.worklogRepo.save(worklog);
  }

  async updateWorklog(date: string, dto: UpdateWorklogDto): Promise<DailyWorklogEntity> {
    const worklog = await this.getOrCreateWorklog(date);

    if (dto.ttInOutRecords !== undefined) {
      worklog.ttInOutRecords = dto.ttInOutRecords;
    }
    if (dto.ttChangeRecords !== undefined) {
      worklog.ttChangeRecords = dto.ttChangeRecords;
    }
    if (dto.notes !== undefined) {
      worklog.notes = dto.notes;
    }

    return this.worklogRepo.save(worklog);
  }

  async deleteTTInOut(date: string, index: number): Promise<DailyWorklogEntity> {
    const worklog = await this.getOrCreateWorklog(date);

    if (worklog.ttInOutRecords && index >= 0 && index < worklog.ttInOutRecords.length) {
      worklog.ttInOutRecords.splice(index, 1);
    }

    return this.worklogRepo.save(worklog);
  }

  async deleteTTChange(date: string, index: number): Promise<DailyWorklogEntity> {
    const worklog = await this.getOrCreateWorklog(date);

    if (worklog.ttChangeRecords && index >= 0 && index < worklog.ttChangeRecords.length) {
      worklog.ttChangeRecords.splice(index, 1);
    }

    return this.worklogRepo.save(worklog);
  }

  // 월별 평균 잔압 계산
  async getMonthlyPressureStats(year: number, month: number): Promise<MonthlyPressureStatsDto> {
    const startDate = `${year}-${String(month).padStart(2, '0')}-01`;
    // 해당 월의 마지막 날 계산 (다음 달 0일 = 이번 달 마지막 날)
    const lastDay = new Date(year, month, 0).getDate();
    const endDate = `${year}-${String(month).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;

    const worklogs = await this.worklogRepo.find({
      where: {
        date: Between(startDate, endDate),
      },
    });

    let totalPressureSum = 0;
    let recordCount = 0;

    for (const worklog of worklogs) {
      if (worklog.ttChangeRecords) {
        for (const record of worklog.ttChangeRecords) {
          // 교체 전 잔압값 사용 (나가는 T/T 잔압)
          totalPressureSum += record.pressureBefore;
          recordCount++;
        }
      }
    }

    const averagePressure = recordCount > 0 ? Math.round((totalPressureSum / recordCount) * 100) / 100 : 0;

    return {
      year,
      month,
      totalPressureSum,
      recordCount,
      averagePressure,
    };
  }

  // 월별 평균 손실률 계산
  async getMonthlyLossStats(year: number, month: number): Promise<MonthlyLossStatsDto> {
    // 전월 마지막 날부터 해당 월 마지막 날까지 조회 (전날 flowMeter 비교 위해)
    const prevMonth = month === 1 ? 12 : month - 1;
    const prevYear = month === 1 ? year - 1 : year;
    const prevLastDay = new Date(prevYear, prevMonth, 0).getDate();
    const prevMonthLastDate = `${prevYear}-${String(prevMonth).padStart(2, '0')}-${String(prevLastDay).padStart(2, '0')}`;

    const startDate = `${year}-${String(month).padStart(2, '0')}-01`;
    const lastDay = new Date(year, month, 0).getDate();
    const endDate = `${year}-${String(month).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;

    // 전월 마지막 날 + 해당 월 전체 조회
    const salesRecords = await this.salesRepo.find({
      where: {
        date: Between(prevMonthLastDate, endDate),
      },
      order: { date: 'ASC' },
    });

    // 날짜별 Map 생성
    const salesMap = new Map<string, SalesRecordEntity>();
    for (const record of salesRecords) {
      salesMap.set(record.date, record);
    }

    let totalLossRate = 0;
    let validCount = 0;

    // 해당 월 1일부터 마지막 날까지 손실률 계산
    for (let day = 1; day <= lastDay; day++) {
      const dateStr = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
      const currentSales = salesMap.get(dateStr);

      const currentFlowMeter = Number(currentSales?.flowMeter) || 0;
      const currentTotalKg = Number(currentSales?.totalKg) || 0;

      if (!currentSales || currentFlowMeter <= 0 || currentTotalKg <= 0) {
        continue;
      }

      // 전날 날짜 계산 (타임존 문제 방지)
      const prevDate = new Date(year, month - 1, day - 1);
      const prevDateStr = `${prevDate.getFullYear()}-${String(prevDate.getMonth() + 1).padStart(2, '0')}-${String(prevDate.getDate()).padStart(2, '0')}`;
      const prevSales = salesMap.get(prevDateStr);

      const prevFlowMeter = Number(prevSales?.flowMeter) || 0;

      if (!prevSales || prevFlowMeter <= 0) {
        continue;
      }

      const flowDiff = currentFlowMeter - prevFlowMeter;
      if (flowDiff > 0) {
        const lossRate = ((currentTotalKg - flowDiff) / flowDiff) * 100;
        totalLossRate += lossRate;
        validCount++;
      }
    }

    const averageLossRate = validCount > 0 ? Math.round(totalLossRate / validCount * 100) / 100 : 0;

    return {
      year,
      month,
      recordCount: validCount,
      averageLossRate,
    };
  }

  // 월별 매출 통계
  async getMonthlySalesStats(year: number, month: number): Promise<MonthlySalesStatsDto> {
    const startDate = `${year}-${String(month).padStart(2, '0')}-01`;
    const lastDay = new Date(year, month, 0).getDate();
    const endDate = `${year}-${String(month).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;

    const salesRecords = await this.salesRepo.find({
      where: {
        date: Between(startDate, endDate),
      },
    });

    let totalKg = 0;
    let totalVehicles = 0;
    let recordCount = 0;

    for (const record of salesRecords) {
      const kg = Number(record.totalKg) || 0;
      const vehicles = Number(record.totalVehicles) || 0;
      if (kg > 0 || vehicles > 0) {
        totalKg += kg;
        totalVehicles += vehicles;
        recordCount++;
      }
    }

    const dailyAvgKg = recordCount > 0 ? Math.round(totalKg / recordCount * 10) / 10 : 0;
    const dailyAvgVehicles = recordCount > 0 ? Math.round(totalVehicles / recordCount * 10) / 10 : 0;

    return {
      year,
      month,
      totalKg,
      totalVehicles,
      recordCount,
      dailyAvgKg,
      dailyAvgVehicles,
    };
  }

  // 특이사항 검색 (최근 1년)
  async searchNotes(keyword: string): Promise<{ date: string; notes: string }[]> {
    // 1년 전 날짜 계산
    const now = new Date();
    const oneYearAgo = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate());
    const startDate = `${oneYearAgo.getFullYear()}-${String(oneYearAgo.getMonth() + 1).padStart(2, '0')}-${String(oneYearAgo.getDate()).padStart(2, '0')}`;

    const worklogs = await this.worklogRepo.find({
      where: {
        date: MoreThanOrEqual(startDate),
        notes: Like(`%${keyword}%`),
      },
      order: { date: 'DESC' },
    });

    return worklogs
      .filter(w => w.notes)
      .map(w => ({
        date: w.date,
        notes: w.notes!,
      }));
  }

  // 날짜 범위 매출 조회 (그래프용)
  async getSalesRange(startDate: string, endDate: string): Promise<DailySalesDto[]> {
    const salesRecords = await this.salesRepo.find({
      where: {
        date: Between(startDate, endDate),
      },
      order: { date: 'ASC' },
    });

    // 날짜별 Map 생성
    const salesMap = new Map<string, SalesRecordEntity>();
    for (const record of salesRecords) {
      salesMap.set(record.date, record);
    }

    // 시작일부터 종료일까지 모든 날짜 생성 (타임존 문제 방지)
    const result: DailySalesDto[] = [];
    const [startYear, startMonth, startDay] = startDate.split('-').map(Number);
    const [endYear, endMonth, endDay] = endDate.split('-').map(Number);

    let current = new Date(startYear, startMonth - 1, startDay);
    const endDateObj = new Date(endYear, endMonth - 1, endDay);

    while (current <= endDateObj) {
      const dateStr = `${current.getFullYear()}-${String(current.getMonth() + 1).padStart(2, '0')}-${String(current.getDate()).padStart(2, '0')}`;
      const record = salesMap.get(dateStr);

      result.push({
        date: dateStr,
        totalKg: Number(record?.totalKg) || 0,
        totalVehicles: Number(record?.totalVehicles) || 0,
      });

      current.setDate(current.getDate() + 1);
    }

    return result;
  }

  // 월말 자동 월별 통계 저장 (매월 마지막 날 23:50 KST = UTC 14:50)
  @Cron('50 14 28-31 * *')
  async saveMonthlyStatsIfLastDay() {
    const now = new Date();
    const kstOffset = 9 * 60;
    const kstTime = new Date(now.getTime() + kstOffset * 60 * 1000);

    const year = kstTime.getFullYear();
    const month = kstTime.getMonth() + 1;
    const today = kstTime.getDate();
    const lastDay = new Date(year, month, 0).getDate();

    // 마지막 날인지 확인
    if (today !== lastDay) {
      return;
    }

    this.logger.log(`Saving monthly stats for ${year}-${month}`);
    await this.saveMonthlyStats(year, month);
  }

  // 월별 통계 저장
  async saveMonthlyStats(year: number, month: number): Promise<MonthlyStatsEntity> {
    // 이미 저장된 데이터가 있는지 확인
    let stats = await this.monthlyStatsRepo.findOne({
      where: { year, month },
    });

    // 평균 잔압 계산
    const pressureStats = await this.getMonthlyPressureStats(year, month);
    // 평균 손실률 계산
    const lossStats = await this.getMonthlyLossStats(year, month);

    if (!stats) {
      stats = this.monthlyStatsRepo.create({ year, month });
    }

    stats.averagePressure = pressureStats.averagePressure;
    stats.averageLossRate = lossStats.averageLossRate;
    stats.recordCount = Math.max(pressureStats.recordCount, lossStats.recordCount);

    this.logger.log(`Monthly stats saved: ${year}-${month}, pressure: ${stats.averagePressure}bar, loss: ${stats.averageLossRate}%`);

    return this.monthlyStatsRepo.save(stats);
  }

  // 저장된 월별 통계 조회
  async getMonthlyStats(year: number, month: number): Promise<MonthlyStatsEntity | null> {
    return this.monthlyStatsRepo.findOne({
      where: { year, month },
    });
  }

  // 저장된 월별 통계 전체 조회
  async getAllMonthlyStats(): Promise<MonthlyStatsEntity[]> {
    return this.monthlyStatsRepo.find({
      order: { year: 'DESC', month: 'DESC' },
    });
  }
}
