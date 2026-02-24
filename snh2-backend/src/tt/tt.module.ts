import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TTStatusEntity } from '../entities';
import { TTService } from './tt.service';
import { TTController } from './tt.controller';

@Module({
  imports: [TypeOrmModule.forFeature([TTStatusEntity])],
  controllers: [TTController],
  providers: [TTService],
  exports: [TTService],
})
export class TTModule {}
