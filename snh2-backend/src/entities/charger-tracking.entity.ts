import { Entity, PrimaryColumn, Column, UpdateDateColumn } from 'typeorm';

/**
 * 충전기 추적 상태의 스냅샷 (단일 행, id=1)
 *
 * 추적 상태는 메모리에 살고, 이 테이블은 재시작 대비 백업이다.
 * 배포로 서버가 내려갔다 떠도 "어느 충전기에 뭐가 몇 시부터"를 잃지 않아야
 * 대기시간이 추정 불가(확인 중)로 떨어지는 공백이 생기지 않는다.
 */
@Entity('charger_tracking')
export class ChargerTrackingEntity {
  @PrimaryColumn()
  id: number;

  @Column({ type: 'jsonb' })
  state: {
    chargerA: { type: 'car' | 'bus' | null; startTime: string | null };
    chargerB: { type: 'car' | 'bus' | null; startTime: string | null };
    prevCars: number | null;
    prevBuses: number | null;
  };

  @UpdateDateColumn()
  updatedAt: Date;
}
