import { IsNumber, IsString, IsOptional, Min } from 'class-validator';

export class UpdateMealDto {
  @IsString()
  @IsOptional()
  lunch?: string | null;

  @IsString()
  @IsOptional()
  dinner?: string | null;
}

export class UpdateSalesDto {
  @IsNumber()
  @IsOptional()
  @Min(0)
  flowMeter?: number | null;

  @IsNumber()
  @Min(0)
  totalKg: number;

  @IsNumber()
  @Min(0)
  totalVehicles: number;
}

// 월별 매출 통계 응답
export class MonthlySalesStatsDto {
  year: number;
  month: number;
  totalKg: number;
  totalVehicles: number;
  recordCount: number;
  dailyAvgKg: number;
  dailyAvgVehicles: number;
}

// 일별 매출 데이터
export class DailySalesDto {
  date: string;
  totalKg: number;
  totalVehicles: number;
}
