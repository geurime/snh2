import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { StationStatusEntity } from '../entities';
import { StationService } from './station.service';
import { StationController } from './station.controller';

@Module({
  imports: [TypeOrmModule.forFeature([StationStatusEntity])],
  controllers: [StationController],
  providers: [StationService],
  exports: [StationService],
})
export class StationModule {}
