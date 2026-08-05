import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
import { HydrogenModule } from './hydrogen/hydrogen.module';
import { StationModule } from './station/station.module';
import { TTModule } from './tt/tt.module';
import { RecordsModule } from './records/records.module';
import { SuggestionModule } from './suggestion/suggestion.module';
import { AuthModule } from './auth/auth.module';
import {
  StationStatusEntity,
  TTStatusEntity,
  DailyMealEntity,
  SalesRecordEntity,
  DailyWorklogEntity,
  MonthlyStatsEntity,
  SuggestionEntity,
} from './entities';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, 'public'),
      serveStaticOptions: {
        index: ['index.html'],
      },
    }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        url: configService.get<string>('DATABASE_URL'),
        entities: [
          StationStatusEntity,
          TTStatusEntity,
          DailyMealEntity,
          SalesRecordEntity,
          DailyWorklogEntity,
          MonthlyStatsEntity,
          SuggestionEntity,
                ],
        synchronize: configService.get<string>('NODE_ENV') !== 'production', // 프로덕션에서는 마이그레이션 사용
        ssl: configService.get<string>('NODE_ENV') === 'production'
          ? { rejectUnauthorized: false }
          : false,
      }),
    }),
    ScheduleModule.forRoot(),
    AuthModule,
    HydrogenModule,
    StationModule,
    TTModule,
    RecordsModule,
    SuggestionModule,
  ],
})
export class AppModule {}
