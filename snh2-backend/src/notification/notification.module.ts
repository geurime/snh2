import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NotificationService } from './notification.service';
import { FcmTokenEntity } from '../entities';

@Module({
  imports: [TypeOrmModule.forFeature([FcmTokenEntity])],
  providers: [NotificationService],
  exports: [NotificationService],
})
export class NotificationModule {}
