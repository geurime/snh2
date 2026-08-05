import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * 충전기 추적 스냅샷 테이블.
 *
 * 추적 상태가 서버 메모리에만 있어 배포·재시작 때마다 초기화됐고,
 * 그 공백이 대기시간 표시를 기본값 상수(승용 5분 고정)로 만들었다.
 * 폴링마다 스냅샷을 남기고 부팅 때 복원해 공백을 없앤다.
 */
export class AddChargerTracking1785900000000 implements MigrationInterface {
  name = 'AddChargerTracking1785900000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "charger_tracking" (
        "id" integer PRIMARY KEY,
        "state" jsonb NOT NULL,
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now()
      )
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "charger_tracking"`);
  }
}
