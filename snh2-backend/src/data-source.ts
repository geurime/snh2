import { DataSource, DataSourceOptions } from 'typeorm';
import { config } from 'dotenv';
import {
  StationStatusEntity,
  TTStatusEntity,
  DailyMealEntity,
  SalesRecordEntity,
  DailyWorklogEntity,
  MonthlyStatsEntity,
  SuggestionEntity,
  ChargerTrackingEntity,
} from './entities';

// .env 파일 로드
config();

export const dataSourceOptions: DataSourceOptions = {
  type: 'postgres',
  url: process.env.DATABASE_URL,
  entities: [
    StationStatusEntity,
    TTStatusEntity,
    DailyMealEntity,
    SalesRecordEntity,
    DailyWorklogEntity,
    MonthlyStatsEntity,
    SuggestionEntity,
    ChargerTrackingEntity,
  ],
  migrations: ['dist/migrations/*.js'],
  ssl: process.env.NODE_ENV === 'production'
    ? { rejectUnauthorized: false }
    : false,
};

const dataSource = new DataSource(dataSourceOptions);
export default dataSource;
