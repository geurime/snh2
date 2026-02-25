import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, Index } from 'typeorm';

@Entity('monthly_stats')
@Index(['year', 'month'])
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
