import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TTStatusEntity } from '../entities';
import { UpdateTTStatusDto, UpdateTTScheduleDto } from './dto/update-tt.dto';

@Injectable()
export class TTService {
  private readonly logger = new Logger(TTService.name);
  private readonly PRESSURE_JUMP_THRESHOLD = 70;

  constructor(
    @InjectRepository(TTStatusEntity)
    private readonly ttRepo: Repository<TTStatusEntity>,
  ) {}

  private getKSTDate(offsetDays: number = 0): string {
    const now = new Date();
    const kstOffset = 9 * 60; // KST = UTC+9
    const kstTime = new Date(now.getTime() + kstOffset * 60 * 1000);
    kstTime.setDate(kstTime.getDate() + offsetDays);
    return kstTime.toISOString().split('T')[0];
  }

  private getTodayDate(): string {
    return this.getKSTDate(0);
  }

  private getTomorrowDate(): string {
    return this.getKSTDate(1);
  }

  async getStatusByDate(date: string): Promise<TTStatusEntity> {
    let status = await this.ttRepo.findOne({ where: { date } });

    if (!status) {
      status = await this.ttRepo.save({
        date,
        totalCount: 0,
        currentIndex: 1,
        schedules: [],
      });
    }

    return status;
  }

  async getTodayStatus(): Promise<TTStatusEntity> {
    return this.getStatusByDate(this.getTodayDate());
  }

  async getTomorrowStatus(): Promise<TTStatusEntity> {
    return this.getStatusByDate(this.getTomorrowDate());
  }

  async updateTodayStatus(dto: UpdateTTStatusDto): Promise<TTStatusEntity> {
    const status = await this.getTodayStatus();

    if (dto.totalCount !== undefined) {
      status.totalCount = dto.totalCount;
    }
    if (dto.currentIndex !== undefined) {
      status.currentIndex = dto.currentIndex;
    }

    return this.ttRepo.save(status);
  }

  /**
   * T/T 일정은 내일 날짜로 저장 (오후에 내일 일정 입력)
   * 일정(시간)만 저장, totalCount/currentIndex는 별도 관리
   */
  async updateSchedule(dto: UpdateTTScheduleDto): Promise<TTStatusEntity> {
    const tomorrow = this.getTomorrowDate();
    const status = await this.getStatusByDate(tomorrow);
    status.schedules = dto.schedules;
    return this.ttRepo.save(status);
  }

  /**
   * 특정 날짜의 T/T 일정 수정
   */
  async updateScheduleByDate(date: string, schedules: string[]): Promise<TTStatusEntity> {
    const status = await this.getStatusByDate(date);
    status.schedules = schedules;
    return this.ttRepo.save(status);
  }

  /**
   * 잔압 변화 감지하여 T/T 교체 시 currentIndex 자동 증가
   * 잔압이 +70 이상 급상승하면 새 T/T가 연결된 것으로 판단
   * @returns { changed: boolean, pressureBefore: number | null } 교체 감지 여부 및 교체 전 잔압
   */
  async checkPressureJump(newPressure: number): Promise<{ changed: boolean; pressureBefore: number | null }> {
    if (newPressure === null || newPressure === undefined) {
      return { changed: false, pressureBefore: null };
    }

    const status = await this.getTodayStatus();
    const lastPressure = status.lastPressure;

    // 첫 측정이면 그냥 저장
    if (lastPressure === null || lastPressure === undefined) {
      status.lastPressure = newPressure;
      await this.ttRepo.save(status);
      return { changed: false, pressureBefore: null };
    }

    const pressureJump = newPressure - lastPressure;
    let changed = false;

    // 압력이 70 이상 급상승하면 T/T 교체로 판단
    if (pressureJump >= this.PRESSURE_JUMP_THRESHOLD) {
      // totalCount 범위 내에서만 증가
      if (status.currentIndex < status.totalCount) {
        status.currentIndex += 1;
        changed = true;
        this.logger.log(
          `T/T change detected! Pressure: ${lastPressure} -> ${newPressure} (+${pressureJump}), Index: ${status.currentIndex}/${status.totalCount}`,
        );
      }
    }

    // 항상 lastPressure 업데이트
    status.lastPressure = newPressure;
    await this.ttRepo.save(status);

    return { changed, pressureBefore: changed ? lastPressure : null };
  }
}
