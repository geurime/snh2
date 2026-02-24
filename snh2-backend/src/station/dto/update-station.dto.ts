import { IsEnum, IsString, IsOptional, IsNumber, Min, Max } from 'class-validator';
import { ChargerStatus, CarWashStatus, TTStatus } from '../../entities';

export class UpdateChargerDto {
  @IsOptional()
  @IsEnum(ChargerStatus)
  chargerA?: ChargerStatus;

  @IsOptional()
  @IsEnum(ChargerStatus)
  chargerB?: ChargerStatus;
}

export class UpdateCarWashDto {
  @IsEnum(CarWashStatus)
  carWashStatus: CarWashStatus;
}

export class UpdateAnnouncementDto {
  @IsString()
  @IsOptional()
  announcement: string | null;
}

// T/T 입고 DTO
export class TTIncomingDto {
  @IsEnum(['A', 'B'])
  target: 'A' | 'B';  // 어느 T/T에 입고하는지
}

// T/T 교체 DTO
export class TTChangeDto {
  @IsEnum(['A>B', 'B>A'])
  direction: 'A>B' | 'B>A';  // 교체 방향

  @IsNumber()
  @Min(0)
  @Max(500)
  pressureBefore: number;  // 교체 전 잔압 (나가는 T/T)
}

// T/T 상태 직접 설정 DTO
export class SetTTStatusDto {
  @IsEnum(TTStatus)
  ttAStatus: TTStatus;

  @IsEnum(TTStatus)
  ttBStatus: TTStatus;
}

// T/T 상태 응답
export interface TTStatusResponse {
  ttAStatus: TTStatus;
  ttBStatus: TTStatus;
}

// T/T 작업 결과 응답
export interface TTOperationResult {
  success: boolean;
  message?: string;
  ttAStatus: TTStatus;
  ttBStatus: TTStatus;
}
