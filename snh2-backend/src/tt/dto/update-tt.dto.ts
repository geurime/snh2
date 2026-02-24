import { IsNumber, IsArray, IsOptional, IsString, Min } from 'class-validator';

export class UpdateTTStatusDto {
  @IsNumber()
  @Min(0)
  @IsOptional()
  totalCount?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  currentIndex?: number;
}

export class UpdateTTScheduleDto {
  @IsArray()
  @IsString({ each: true })
  schedules: string[];
}
