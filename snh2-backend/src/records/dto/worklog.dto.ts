import { IsString, IsNumber, IsOptional, IsArray, ValidateNested, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class TTInOutRecordDto {
  @IsString()
  time: string;

  @IsString()
  description: string;
}

export class TTChangeRecordDto {
  @IsString()
  time: string;

  @IsString()
  direction: string;

  @IsNumber()
  @Min(0)
  meterValue: number;

  @IsNumber()
  @Min(1)
  monthlyIndex: number;

  @IsNumber()
  @Min(0)
  pressureBefore: number;
}

export class AddTTInOutDto {
  @ValidateNested()
  @Type(() => TTInOutRecordDto)
  record: TTInOutRecordDto;
}

export class AddTTChangeDto {
  @ValidateNested()
  @Type(() => TTChangeRecordDto)
  record: TTChangeRecordDto;
}

export class UpdateWorklogNotesDto {
  @IsString()
  @IsOptional()
  notes: string | null;
}

export class UpdateWorklogDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => TTInOutRecordDto)
  @IsOptional()
  ttInOutRecords?: TTInOutRecordDto[];

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => TTChangeRecordDto)
  @IsOptional()
  ttChangeRecords?: TTChangeRecordDto[];

  @IsString()
  @IsOptional()
  notes?: string | null;
}

// 월별 평균 잔압 응답
export class MonthlyPressureStatsDto {
  year: number;
  month: number;
  totalPressureSum: number;
  recordCount: number;
  averagePressure: number;
}

// 월별 평균 손실률 응답
export class MonthlyLossStatsDto {
  year: number;
  month: number;
  recordCount: number;      // 유효한 손실률 계산 건수
  averageLossRate: number;  // 평균 손실률 (%)
}
