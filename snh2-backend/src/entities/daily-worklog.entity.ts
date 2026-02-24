import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

// T/T 입출고 기록
export interface TTInOutRecord {
  time: string;         // HH:mm
  description: string;  // 예: "T/T A 입고"
}

// T/T 교체 기록
export interface TTChangeRecord {
  time: string;          // HH:mm
  direction: string;     // 예: "A→B", "B→A"
  meterValue: number;    // 계량기값
  monthlyIndex: number;  // 당월 순번
  pressureBefore: number; // 교체 전 잔압
}

@Entity('daily_worklog')
export class DailyWorklogEntity {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'date' })
  date: string;

  // T/T 입출고 기록 배열
  @Column({ type: 'simple-json', nullable: true })
  ttInOutRecords: TTInOutRecord[] | null;

  // T/T 교체 기록 배열
  @Column({ type: 'simple-json', nullable: true })
  ttChangeRecords: TTChangeRecord[] | null;

  // 특이사항
  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
