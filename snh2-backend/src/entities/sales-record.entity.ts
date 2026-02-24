import { Entity, Column, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

@Entity('sales_record')
export class SalesRecordEntity {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'date', unique: true })
  date: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  flowMeter: number | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  totalKg: number;

  @Column({ default: 0 })
  totalVehicles: number;

  @UpdateDateColumn()
  updatedAt: Date;
}
