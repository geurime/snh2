import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

@Entity('monthly_stats')
export class MonthlyStatsEntity {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  year: number;

  @Column()
  month: number;

  @Column({ type: 'decimal', precision: 5, scale: 2, nullable: true })
  averagePressure: number | null;

  @Column({ type: 'decimal', precision: 5, scale: 2, nullable: true })
  averageLossRate: number | null;

  @Column({ default: 0 })
  recordCount: number;

  @CreateDateColumn()
  createdAt: Date;
}
