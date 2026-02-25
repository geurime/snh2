import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { StationService } from './station.service';
import {
  StationStatusEntity,
  ChargerStatus,
  CarWashStatus,
  TTStatus,
} from '../entities';

describe('StationService', () => {
  let service: StationService;
  let repository: Repository<StationStatusEntity>;

  const mockStation: StationStatusEntity = {
    id: 1,
    chargerA: ChargerStatus.OPERATING,
    chargerB: ChargerStatus.OPERATING,
    carWashStatus: CarWashStatus.OPERATING,
    ttAStatus: TTStatus.EMPTY,
    ttBStatus: TTStatus.EMPTY,
    announcement: null,
    updatedAt: new Date(),
  };

  const mockRepository = {
    findOne: jest.fn(),
    save: jest.fn(),
    count: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        StationService,
        {
          provide: getRepositoryToken(StationStatusEntity),
          useValue: mockRepository,
        },
      ],
    }).compile();

    service = module.get<StationService>(StationService);
    repository = module.get<Repository<StationStatusEntity>>(
      getRepositoryToken(StationStatusEntity),
    );

    jest.clearAllMocks();
  });

  describe('getStatus', () => {
    it('충전소 상태 조회 성공', async () => {
      mockRepository.findOne.mockResolvedValue(mockStation);

      const result = await service.getStatus();

      expect(result).toEqual(mockStation);
      expect(mockRepository.findOne).toHaveBeenCalledWith({ where: { id: 1 } });
    });

    it('상태 없으면 기본값 생성', async () => {
      mockRepository.findOne.mockResolvedValue(null);
      mockRepository.save.mockResolvedValue(mockStation);

      const result = await service.getStatus();

      expect(mockRepository.save).toHaveBeenCalled();
      expect(result).toEqual(mockStation);
    });
  });

  describe('updateCharger', () => {
    it('충전기 A 상태 업데이트', async () => {
      const updatedStation = {
        ...mockStation,
        chargerA: ChargerStatus.BROKEN,
      };
      mockRepository.findOne.mockResolvedValue({ ...mockStation });
      mockRepository.save.mockResolvedValue(updatedStation);

      const result = await service.updateCharger({
        chargerA: ChargerStatus.BROKEN,
      });

      expect(result.chargerA).toBe(ChargerStatus.BROKEN);
    });

    it('충전기 B 상태 업데이트', async () => {
      const updatedStation = {
        ...mockStation,
        chargerB: ChargerStatus.MAINTENANCE,
      };
      mockRepository.findOne.mockResolvedValue({ ...mockStation });
      mockRepository.save.mockResolvedValue(updatedStation);

      const result = await service.updateCharger({
        chargerB: ChargerStatus.MAINTENANCE,
      });

      expect(result.chargerB).toBe(ChargerStatus.MAINTENANCE);
    });
  });

  describe('ttIncoming', () => {
    it('빈통에 T/T 입고 성공 (둘 다 비어있을 때 → 사용중)', async () => {
      mockRepository.findOne.mockResolvedValue({
        ...mockStation,
        ttAStatus: TTStatus.EMPTY,
        ttBStatus: TTStatus.EMPTY,
      });
      mockRepository.save.mockImplementation((entity) =>
        Promise.resolve(entity),
      );

      const result = await service.ttIncoming({ target: 'A' });

      expect(result.success).toBe(true);
      expect(result.ttAStatus).toBe(TTStatus.IN_USE);
    });

    it('빈통에 T/T 입고 성공 (다른쪽 사용중 → 대기)', async () => {
      mockRepository.findOne.mockResolvedValue({
        ...mockStation,
        ttAStatus: TTStatus.IN_USE,
        ttBStatus: TTStatus.EMPTY,
      });
      mockRepository.save.mockImplementation((entity) =>
        Promise.resolve(entity),
      );

      const result = await service.ttIncoming({ target: 'B' });

      expect(result.success).toBe(true);
      expect(result.ttBStatus).toBe(TTStatus.STANDBY);
    });

    it('빈통이 아니면 입고 실패', async () => {
      mockRepository.findOne.mockResolvedValue({
        ...mockStation,
        ttAStatus: TTStatus.IN_USE,
        ttBStatus: TTStatus.EMPTY,
      });

      const result = await service.ttIncoming({ target: 'A' });

      expect(result.success).toBe(false);
      expect(result.message).toContain('빈통이 아닙니다');
    });
  });

  describe('ttChange', () => {
    it('T/T 교체 성공 (A>B)', async () => {
      mockRepository.findOne.mockResolvedValue({
        ...mockStation,
        ttAStatus: TTStatus.IN_USE,
        ttBStatus: TTStatus.STANDBY,
      });
      mockRepository.save.mockImplementation((entity) =>
        Promise.resolve(entity),
      );

      const result = await service.ttChange({
        direction: 'A>B',
        pressureBefore: 55,
      });

      expect(result.success).toBe(true);
      expect(result.ttAStatus).toBe(TTStatus.EMPTY);
      expect(result.ttBStatus).toBe(TTStatus.IN_USE);
    });

    it('사용중 아닌 T/T 교체 시도시 실패', async () => {
      mockRepository.findOne.mockResolvedValue({
        ...mockStation,
        ttAStatus: TTStatus.EMPTY,
        ttBStatus: TTStatus.STANDBY,
      });

      const result = await service.ttChange({
        direction: 'A>B',
        pressureBefore: 55,
      });

      expect(result.success).toBe(false);
      expect(result.message).toContain('사용 중이 아닙니다');
    });

    it('대기 상태 아닌 T/T로 교체 시도시 실패', async () => {
      mockRepository.findOne.mockResolvedValue({
        ...mockStation,
        ttAStatus: TTStatus.IN_USE,
        ttBStatus: TTStatus.EMPTY,
      });

      const result = await service.ttChange({
        direction: 'A>B',
        pressureBefore: 55,
      });

      expect(result.success).toBe(false);
      expect(result.message).toContain('대기 상태가 아닙니다');
    });
  });
});
