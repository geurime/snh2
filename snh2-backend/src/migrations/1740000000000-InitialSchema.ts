import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * 초기 스키마 마이그레이션
 *
 * 이 마이그레이션은 기존 synchronize: true로 생성된 테이블들을 기록합니다.
 * 프로덕션 DB에는 이미 테이블이 존재하므로, 첫 배포 시에는
 * migration:run 대신 테이블이 이미 있음을 확인하고 스킵합니다.
 *
 * 새 환경에서는 이 마이그레이션으로 초기 테이블이 생성됩니다.
 */
export class InitialSchema1740000000000 implements MigrationInterface {
  name = 'InitialSchema1740000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // station_status 테이블
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "station_status" (
        "id" SERIAL PRIMARY KEY,
        "chargerA" varchar DEFAULT 'operating',
        "chargerB" varchar DEFAULT 'operating',
        "carWashStatus" varchar DEFAULT 'operating',
        "ttAStatus" varchar DEFAULT 'empty',
        "ttBStatus" varchar DEFAULT 'empty',
        "announcement" text,
        "updatedAt" TIMESTAMP DEFAULT now()
      )
    `);

    // tt_status 테이블
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "tt_status" (
        "id" SERIAL PRIMARY KEY,
        "date" date NOT NULL,
        "totalCount" integer DEFAULT 0,
        "currentIndex" integer DEFAULT 0,
        "lastPressure" integer,
        "schedules" text,
        "updatedAt" TIMESTAMP DEFAULT now()
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_tt_status_date" ON "tt_status" ("date")`);

    // daily_meal 테이블
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "daily_meal" (
        "id" SERIAL PRIMARY KEY,
        "date" date NOT NULL,
        "lunch" text,
        "dinner" text
      )
    `);

    // sales_record 테이블
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "sales_record" (
        "id" SERIAL PRIMARY KEY,
        "date" date UNIQUE NOT NULL,
        "flowMeter" decimal(10,2),
        "totalKg" decimal(10,2) DEFAULT 0,
        "totalVehicles" integer DEFAULT 0,
        "updatedAt" TIMESTAMP DEFAULT now()
      )
    `);

    // daily_worklog 테이블
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "daily_worklog" (
        "id" SERIAL PRIMARY KEY,
        "date" date NOT NULL,
        "ttInOutRecords" text,
        "ttChangeRecords" text,
        "notes" text,
        "createdAt" TIMESTAMP DEFAULT now(),
        "updatedAt" TIMESTAMP DEFAULT now()
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_daily_worklog_date" ON "daily_worklog" ("date")`);

    // monthly_stats 테이블
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "monthly_stats" (
        "id" SERIAL PRIMARY KEY,
        "year" integer NOT NULL,
        "month" integer NOT NULL,
        "averagePressure" decimal(5,2),
        "averageLossRate" decimal(5,2),
        "recordCount" integer DEFAULT 0,
        "createdAt" TIMESTAMP DEFAULT now()
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_monthly_stats_year_month" ON "monthly_stats" ("year", "month")`);

    // suggestion 테이블
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "suggestion" (
        "id" SERIAL PRIMARY KEY,
        "content" text NOT NULL,
        "createdAt" TIMESTAMP DEFAULT now()
      )
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "suggestion"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "monthly_stats"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "daily_worklog"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "sales_record"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "daily_meal"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "tt_status"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "station_status"`);
  }
}
