import { Controller, Get, Put, Body, Param, Query } from '@nestjs/common';
import { RecordsService } from './records.service';
import { UpdateSalesDto } from './dto/records.dto';
import { UpdateWorklogDto } from './dto/worklog.dto';

@Controller()
export class RecordsController {
  constructor(private readonly recordsService: RecordsService) {}

  // 공개 API
  @Get('meal/today')
  async getTodayMeal() {
    return this.recordsService.getTodayMeal();
  }

  // Sales endpoints (순서 중요: 구체적인 경로가 :date 파라미터보다 먼저 와야 함)
  @Get('sales/stats/monthly')
  async getMonthlySalesStats(
    @Query('year') year: string,
    @Query('month') month: string,
  ) {
    return this.recordsService.getMonthlySalesStats(
      parseInt(year, 10),
      parseInt(month, 10),
    );
  }

  @Get('sales/range')
  async getSalesRange(
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    return this.recordsService.getSalesRange(startDate, endDate);
  }

  @Get('sales/:date')
  async getSalesByDate(@Param('date') date: string) {
    const sales = await this.recordsService.getSalesByDate(date);
    if (!sales) {
      return { date, totalKg: 0, totalVehicles: 0, flowMeter: null };
    }
    // decimal 타입이 문자열로 반환되므로 숫자로 변환
    return {
      ...sales,
      flowMeter: sales.flowMeter !== null ? Number(sales.flowMeter) : null,
      totalKg: Number(sales.totalKg) || 0,
    };
  }

  @Put('sales/:date')
  async updateSales(@Param('date') date: string, @Body() dto: UpdateSalesDto) {
    // 모든 값이 비어있거나 0이면 저장하지 않고 그냥 리턴
    if ((dto.flowMeter === null || dto.flowMeter === undefined) &&
        dto.totalKg === 0 &&
        dto.totalVehicles === 0) {
      return { date, totalKg: 0, totalVehicles: 0, flowMeter: null };
    }
    return this.recordsService.updateSales(date, dto);
  }

  // Worklog endpoints
  @Get('worklog/today')
  async getTodayWorklog() {
    return this.recordsService.getTodayWorklog();
  }

  @Get('worklog/:date')
  async getWorklogByDate(@Param('date') date: string) {
    const worklog = await this.recordsService.getWorklogByDate(date);
    if (!worklog) {
      return {
        date,
        ttInOutRecords: [],
        ttChangeRecords: [],
        notes: null,
      };
    }
    return worklog;
  }

  @Put('worklog/:date')
  async updateWorklog(@Param('date') date: string, @Body() dto: UpdateWorklogDto) {
    return this.recordsService.updateWorklog(date, dto);
  }

  // 월별 평균 잔압
  @Get('worklog/stats/pressure')
  async getMonthlyPressureStats(
    @Query('year') year: string,
    @Query('month') month: string,
  ) {
    return this.recordsService.getMonthlyPressureStats(
      parseInt(year, 10),
      parseInt(month, 10),
    );
  }

  // 월별 평균 손실률
  @Get('worklog/stats/loss')
  async getMonthlyLossStats(
    @Query('year') year: string,
    @Query('month') month: string,
  ) {
    return this.recordsService.getMonthlyLossStats(
      parseInt(year, 10),
      parseInt(month, 10),
    );
  }

}
