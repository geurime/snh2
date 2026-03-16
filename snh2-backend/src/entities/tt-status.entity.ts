import { Entity, Column, PrimaryGeneratedColumn, UpdateDateColumn, Index } from 'typeorm';

@Entity('tt_status')
export class TTStatusEntity {
  @PrimaryGeneratedColumn()
  id: number;

  @Index({ unique: true })
  @Column({ type: 'date', unique: true })
  date: string;

  @Column({ default: 0 })
  totalCount: number;

  @Column({ default: 0 })
  currentIndex: number;

  @Column({ type: 'int', nullable: true })
  lastPressure: number | null;

  @Column({ type: 'simple-array', nullable: true })
  schedules: string[];

  @UpdateDateColumn()
  updatedAt: Date;
}
