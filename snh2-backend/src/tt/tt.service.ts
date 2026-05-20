import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TTStatusEntity } from '../entities';
import { UpdateTTStatusDto } from './dto/update-tt.dto';
import { getKSTDate } from '../common/utils/date.util';

@Injectable()
export class TTService {
  private readonly logger = new Logger(TTService.name);
  private readonly PRESSURE_JUMP_THRESHOLD = 50;
  private readonly COOLDOWN_MS = 3 * 60 * 1000; // 교체 감지 후 3분 쿨다운
  private readonly BUFFER_MS = 5 * 60 * 1000; // 잔압 롤링 버퍼 5분
  private lastChangeTime: number = 0;
  private pressureBuffer: { ts: number; pressure: number }[] = [];

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
   * 잔압이 임계값(PRESSURE_JUMP_THRESHOLD) 이상 급상승하면 새 T/T가 연결된 것으로 판단.
   * 교체 전 잔압은 직전값이 아닌 최근 5분 버퍼의 최소값을 사용
   * (램프 중간값이 폴링에 잡혀 lastPressure가 오염되는 경우 대비).
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
    let pressureBefore: number | null = null;

    // 롤링 버퍼 갱신 (오래된 항목 제거 후 현재 측정값 추가)
    const now = Date.now();
    this.pressureBuffer = this.pressureBuffer.filter(
      (p) => now - p.ts <= this.BUFFER_MS,
    );
    this.pressureBuffer.push({ ts: now, pressure: newPressure });

    // 압력이 임계값 이상 급상승하면 T/T 교체로 판단
    if (pressureJump >= this.PRESSURE_JUMP_THRESHOLD) {
      if (now - this.lastChangeTime < this.COOLDOWN_MS) {
        this.logger.log(
          `T/T change ignored (cooldown): ${lastPressure} -> ${newPressure} (+${pressureJump})`,
        );
      } else {
        // 직전값 대신 최근 5분 버퍼의 최소값을 진짜 "교체 전" 잔압으로 사용
        // (15초 폴링 간격에 램프 중간값이 잡혀 lastPressure가 오염되는 케이스 보정)
        pressureBefore = Math.min(...this.pressureBuffer.map((p) => p.pressure));
        status.currentIndex += 1;
        changed = true;
        this.lastChangeTime = now;
        this.logger.log(
          `T/T change detected! Pressure: ${lastPressure} -> ${newPressure} (+${pressureJump}), before=${pressureBefore}, Index: ${status.currentIndex}/${status.totalCount}`,
        );
        // 감지 직후 버퍼 리셋 (다음 사이클에서 이번 high 값이 최소값에 오염되지 않도록)
        this.pressureBuffer = [{ ts: now, pressure: newPressure }];
      }
    }

    // 항상 lastPressure 업데이트
    status.lastPressure = newPressure;
    await this.ttRepo.save(status);

    return { changed, pressureBefore };
  }
}
