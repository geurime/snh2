import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HttpModule } from '@nestjs/axios';
import { HydrogenService } from './hydrogen.service';
import { HydrogenController } from './hydrogen.controller';
import { StationModule } from '../station/station.module';
import { TTModule } from '../tt/tt.module';
import { RecordsModule } from '../records/records.module';
import { ChargerTrackingEntity } from '../entities';

@Module({
  imports: [
    HttpModule,
    StationModule,
    TTModule,
    RecordsModule,
    TypeOrmModule.forFeature([ChargerTrackingEntity]),
  ],
  controllers: [HydrogenController],
  providers: [HydrogenService],
})
export class HydrogenModule {}
