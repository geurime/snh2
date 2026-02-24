import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';
import { DailyMealEntity, SalesRecordEntity, DailyWorklogEntity, MonthlyStatsEntity } from '../entities';
import { RecordsService } from './records.service';
import { RecordsController } from './records.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([DailyMealEntity, SalesRecordEntity, DailyWorklogEntity, MonthlyStatsEntity]),
    ScheduleModule.forRoot(),
  ],
  controllers: [RecordsController],
  providers: [RecordsService],
  exports: [RecordsService],
})
export class RecordsModule {}
