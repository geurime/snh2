import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TTStatusEntity } from '../entities';
import { TTService } from './tt.service';
import { TTController } from './tt.controller';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([TTStatusEntity]),
    AuthModule,
  ],
  controllers: [TTController],
  providers: [TTService],
  exports: [TTService],
})
export class TTModule {}
