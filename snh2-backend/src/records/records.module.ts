import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DailyMealEntity, SalesRecordEntity, DailyWorklogEntity, MonthlyStatsEntity } from '../entities';
import { RecordsService } from './records.service';
import { RecordsController } from './records.controller';
import { AuthModule } from '../auth/auth.module';
import { NotificationModule } from '../notification/notification.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([DailyMealEntity, SalesRecordEntity, DailyWorklogEntity, MonthlyStatsEntity]),
    AuthModule,
    NotificationModule,
  ],
  controllers: [RecordsController],
  providers: [RecordsService],
  exports: [RecordsService],
})
export class RecordsModule {}
