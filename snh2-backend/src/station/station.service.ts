import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { StationStatusEntity, ChargerStatus, CarWashStatus, TTStatus } from '../entities';
import { UpdateChargerDto, UpdateCarWashDto, UpdateAnnouncementDto, TTIncomingDto, TTChangeDto, TTOperationResult } from './dto/update-station.dto';

@Injectable()
export class StationService implements OnModuleInit {
  constructor(
    @InjectRepository(StationStatusEntity)
    private readonly stationRepo: Repository<StationStatusEntity>,
  ) {}

  async onModuleInit() {
    // 초기 데이터가 없으면 생성
    const count = await this.stationRepo.count();
    if (count === 0) {
      await this.stationRepo.save({
        chargerA: ChargerStatus.OPERATING,
        chargerB: ChargerStatus.OPERATING,
        carWashStatus: CarWashStatus.OPERATING,
        announcement: null,
      });
    }
  }

  async getStatus(): Promise<StationStatusEntity> {
    const status = await this.stationRepo.findOne({ where: { id: 1 } });
    if (!status) {
      return this.stationRepo.save({
        chargerA: ChargerStatus.OPERATING,
        chargerB: ChargerStatus.OPERATING,
        carWashStatus: CarWashStatus.OPERATING,
        announcement: null,
      });
    }
    return status;
  }

  async updateCharger(dto: UpdateChargerDto): Promise<StationStatusEntity> {
    const status = await this.getStatus();
    if (dto.chargerA !== undefined) {
      status.chargerA = dto.chargerA;
    }
    if (dto.chargerB !== undefined) {
      status.chargerB = dto.chargerB;
    }
    return this.stationRepo.save(status);
  }

  async updateCarWash(dto: UpdateCarWashDto): Promise<StationStatusEntity> {
    const status = await this.getStatus();
    status.carWashStatus = dto.carWashStatus;
    return this.stationRepo.save(status);
  }

  async updateAnnouncement(dto: UpdateAnnouncementDto): Promise<StationStatusEntity> {
    const status = await this.getStatus();
    status.announcement = dto.announcement;
    return this.stationRepo.save(status);
  }

  // T/T 입고: 빈통에만 입고 가능
  // - 빈통, 빈통 → 입고하면 사용중
  // - 사용중, 빈통 → 빈통에 입고하면 대기
  async ttIncoming(dto: TTIncomingDto): Promise<TTOperationResult> {
    const status = await this.getStatus();
    const target = dto.target;

    const targetStatus = target === 'A' ? status.ttAStatus : status.ttBStatus;
    const otherStatus = target === 'A' ? status.ttBStatus : status.ttAStatus;

    // 빈통이 아니면 입고 불가
    if (targetStatus !== TTStatus.EMPTY) {
      return {
        success: false,
        message: `T/T ${target}는 빈통이 아닙니다`,
        ttAStatus: status.ttAStatus,
        ttBStatus: status.ttBStatus,
      };
    }

    // 빈통에 입고
    if (otherStatus === TTStatus.EMPTY) {
      // 둘 다 비어있으면 바로 사용중
      if (target === 'A') {
        status.ttAStatus = TTStatus.IN_USE;
      } else {
        status.ttBStatus = TTStatus.IN_USE;
      }
    } else {
      // 다른쪽이 사용중이면 대기
      if (target === 'A') {
        status.ttAStatus = TTStatus.STANDBY;
      } else {
        status.ttBStatus = TTStatus.STANDBY;
      }
    }

    await this.stationRepo.save(status);
    return {
      success: true,
      ttAStatus: status.ttAStatus,
      ttBStatus: status.ttBStatus,
    };
  }

  // T/T 교체: inUse → empty, standby → inUse
  async ttChange(dto: TTChangeDto): Promise<TTOperationResult> {
    const status = await this.getStatus();
    const direction = dto.direction;

    // A>B: A가 사용 중이고 B가 대기 → A는 빈통, B는 사용 중
    // B>A: B가 사용 중이고 A가 대기 → B는 빈통, A는 사용 중
    const fromTT = direction === 'A>B' ? 'A' : 'B';
    const toTT = direction === 'A>B' ? 'B' : 'A';

    const fromStatus = fromTT === 'A' ? status.ttAStatus : status.ttBStatus;
    const toStatus = toTT === 'A' ? status.ttAStatus : status.ttBStatus;

    // 현재 사용 중인 T/T가 아니면 교체 불가
    if (fromStatus !== TTStatus.IN_USE) {
      return {
        success: false,
        message: `T/T ${fromTT}가 사용 중이 아닙니다`,
        ttAStatus: status.ttAStatus,
        ttBStatus: status.ttBStatus,
      };
    }

    // 교체 대상이 대기 상태가 아니면 교체 불가
    if (toStatus !== TTStatus.STANDBY) {
      return {
        success: false,
        message: `T/T ${toTT}가 대기 상태가 아닙니다`,
        ttAStatus: status.ttAStatus,
        ttBStatus: status.ttBStatus,
      };
    }

    // 교체 실행
    if (direction === 'A>B') {
      status.ttAStatus = TTStatus.EMPTY;
      status.ttBStatus = TTStatus.IN_USE;
    } else {
      status.ttBStatus = TTStatus.EMPTY;
      status.ttAStatus = TTStatus.IN_USE;
    }

    await this.stationRepo.save(status);
    return {
      success: true,
      ttAStatus: status.ttAStatus,
      ttBStatus: status.ttBStatus,
    };
  }

  // T/T 상태 직접 설정 (관리자 수동 설정 - 제한 없음)
  async setTTStatus(ttAStatus?: TTStatus, ttBStatus?: TTStatus): Promise<StationStatusEntity> {
    const status = await this.getStatus();
    if (ttAStatus !== undefined) {
      status.ttAStatus = ttAStatus;
    }
    if (ttBStatus !== undefined) {
      status.ttBStatus = ttBStatus;
    }
    return this.stationRepo.save(status);
  }
}
