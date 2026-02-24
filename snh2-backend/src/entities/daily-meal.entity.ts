import { Entity, Column, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

@Entity('daily_meal')
export class DailyMealEntity {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'date' })
  date: string;

  @Column({ type: 'text', nullable: true })
  lunch: string | null;

  @Column({ type: 'text', nullable: true })
  dinner: string | null;

  @UpdateDateColumn()
  updatedAt: Date;
}
