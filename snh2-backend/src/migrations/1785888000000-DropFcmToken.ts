import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * 푸시 알림 제거에 따른 fcm_token 테이블 정리.
 *
 * 마감 보고는 앱이 카톡 공유로 보낸다. 대표가 단톡방에서 보길 원해서
 * 푸시를 받아도 직원이 같은 내용을 손으로 또 쳐야 했다.
 *
 * down()은 테이블만 되살린다. 토큰은 앱이 로그인할 때마다 다시 등록하는
 * 값이라 복구할 필요가 없다 — 되살려도 이미 만료된 토큰이다.
 */
export class DropFcmToken1785888000000 implements MigrationInterface {
  name = 'DropFcmToken1785888000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "fcm_token"`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "fcm_token" (
        "id" SERIAL PRIMARY KEY,
        "token" varchar NOT NULL,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "UQ_fcm_token_token" UNIQUE ("token")
      )
    `);
  }
}
