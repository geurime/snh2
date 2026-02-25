import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { StationStatusEntity } from '../entities';
import { StationService } from './station.service';
import { StationController } from './station.controller';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([StationStatusEntity]),
    AuthModule,
  ],
  controllers: [StationController],
  providers: [StationService],
  exports: [StationService],
})
export class StationModule {}
