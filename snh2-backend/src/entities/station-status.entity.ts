import { Entity, Column, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

export enum ChargerStatus {
  OPERATING = 'operating',
  BROKEN = 'broken',
  MAINTENANCE = 'maintenance',
}

export enum CarWashStatus {
  OPERATING = 'operating',
  MAINTENANCE = 'maintenance',
  CLOSED = 'closed',
}

export enum TTStatus {
  EMPTY = 'empty',       // 빈통
  STANDBY = 'standby',   // 대기 (가득)
  IN_USE = 'inUse',      // 사용 중
}

@Entity('station_status')
export class StationStatusEntity {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({
    type: 'enum',
    enum: ChargerStatus,
    default: ChargerStatus.OPERATING,
  })
  chargerA: ChargerStatus;

  @Column({
    type: 'enum',
    enum: ChargerStatus,
    default: ChargerStatus.OPERATING,
  })
  chargerB: ChargerStatus;

  @Column({
    type: 'enum',
    enum: CarWashStatus,
    default: CarWashStatus.OPERATING,
  })
  carWashStatus: CarWashStatus;

  @Column({
    type: 'enum',
    enum: TTStatus,
    default: TTStatus.EMPTY,
  })
  ttAStatus: TTStatus;

  @Column({
    type: 'enum',
    enum: TTStatus,
    default: TTStatus.EMPTY,
  })
  ttBStatus: TTStatus;

  @Column({ type: 'text', nullable: true })
  announcement: string | null;

  @UpdateDateColumn()
  updatedAt: Date;
}
