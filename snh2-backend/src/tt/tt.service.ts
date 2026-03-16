import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TTStatusEntity } from '../entities';
import { UpdateTTStatusDto } from './dto/update-tt.dto';
import { getKSTDate } from '../common/utils/date.util';

@Injectable()
export class TTService {
  private readonly logger = new Logger(TTService.name);
  private readonly PRESSURE_JUMP_THRESHOLD = 70;

  constructor(
    @InjectRepository(TTStatusEntity)
    private readonly ttRepo: Repository<TTStatusEntity>,
  ) {}

  private getTodayDate(): string {
    return getKSTDate(0);
  }

  private getTomorrowDate(): string {
    return getKSTDate(1);
  }

  async getStatusByDate(date: string): Promise<TTStatusEntity> {
    let status = await this.ttRepo.findOne({ where: { date } });

    if (!status) {
      try {
        status = await this.ttRepo.save({
          date,
          totalCount: 0,
          currentIndex: 1,
          schedules: [],
        });
      } catch {
        // unique 제약으로 인한 중복 삽입 시 기존 레코드 반환
        status = await this.ttRepo.findOne({ where: { date } });
      }
    }

    return status!;
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
