import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as admin from 'firebase-admin';
import * as path from 'path';
import * as fs from 'fs';
import { FcmTokenEntity } from '../entities';

@Injectable()
export class NotificationService implements OnModuleInit {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    @InjectRepository(FcmTokenEntity)
    private readonly tokenRepo: Repository<FcmTokenEntity>,
  ) {}

  onModuleInit() {
    // 환경변수에서 서비스 계정 JSON 읽기 (Railway 등 클라우드 환경)
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
    if (serviceAccountJson) {
      try {
        const serviceAccount = JSON.parse(serviceAccountJson);
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });
        this.logger.log('Firebase Admin SDK initialized from env');
        return;
      } catch (e) {
        this.logger.error('Failed to parse FIREBASE_SERVICE_ACCOUNT env');
      }
    }

    // 로컬 파일 폴백
    const serviceAccountPath = path.join(process.cwd(), 'firebase-service-account.json');
    if (fs.existsSync(serviceAccountPath)) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccountPath),
      });
      this.logger.log('Firebase Admin SDK initialized from file');
    } else {
      this.logger.warn('Firebase service account key not found - push notifications disabled');
    }
  }

  async registerToken(token: string): Promise<void> {
    const existing = await this.tokenRepo.findOne({ where: { token } });
    if (!existing) {
      await this.tokenRepo.save(this.tokenRepo.create({ token }));
      this.logger.log('FCM token registered');
    }
  }

  async unregisterToken(token: string): Promise<void> {
    await this.tokenRepo.delete({ token });
    this.logger.log('FCM token unregistered');
  }

  async sendToAll(title: string, body: string): Promise<void> {
    if (!admin.apps.length) {
      this.logger.warn('Firebase not initialized - skipping notification');
      return;
    }

    const tokens = await this.tokenRepo.find();
    if (tokens.length === 0) return;

    const message: admin.messaging.MulticastMessage = {
      tokens: tokens.map(t => t.token),
      notification: { title, body },
      android: {
        priority: 'high',
        notification: {
          channelId: 'sales_closing',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      this.logger.log(`Notifications sent: ${response.successCount} success, ${response.failureCount} failed`);

      // 실패한 토큰 정리 (유효하지 않은 토큰 삭제)
      if (response.failureCount > 0) {
        const invalidTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success && resp.error?.code === 'messaging/registration-token-not-registered') {
            invalidTokens.push(tokens[idx].token);
          }
        });
        if (invalidTokens.length > 0) {
          for (const t of invalidTokens) {
            await this.tokenRepo.delete({ token: t });
          }
          this.logger.log(`Removed ${invalidTokens.length} invalid tokens`);
        }
      }
    } catch (error) {
      this.logger.error(`Failed to send notifications: ${error.message}`);
    }
  }
}
