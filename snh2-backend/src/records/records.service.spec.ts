import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RecordsService } from './records.service';
import {
  DailyMealEntity,
  SalesRecordEntity,
  DailyWorklogEntity,
  MonthlyStatsEntity,
} from '../entities';

describe('RecordsService', () => {
  let service: RecordsService;
  let mealRepo: jest.Mocked<Repository<DailyMealEntity>>;
  let salesRepo: jest.Mocked<Repository<SalesRecordEntity>>;
  let worklogRepo: jest.Mocked<Repository<DailyWorklogEntity>>;
  let monthlyStatsRepo: jest.Mocked<Repository<MonthlyStatsEntity>>;

  const mockMeal: DailyMealEntity = {
    id: 1,
    date: '2025-01-15',
    lunch: '김치찌개',
    dinner: '된장찌개',
    updatedAt: new Date(),
  };

  const mockSales: SalesRecordEntity = {
    id: 1,
    date: '2025-01-15',
    flowMeter: 1000,
    totalKg: 950,
    totalVehicles: 20,
    updatedAt: new Date(),
  };

  const mockWorklog: DailyWorklogEntity = {
    id: 1,
    date: '2025-01-15',
    ttInOutRecords: [{ time: '09:00', description: 'T/T 입고' }],
    ttChangeRecords: [
      {
        time: '10:00',
        direction: 'A→B',
        meterValue: 100,
        monthlyIndex: 1,
        pressureBefore: 50,
      },
    ],
    notes: '특이사항 없음',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    const mockRepository = () => ({
      findOne: jest.fn(),
      find: jest.fn(),
      save: jest.fn(),
      create: jest.fn(),
    });

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RecordsService,
        { provide: getRepositoryToken(DailyMealEntity), useFactory: mockRepository },
        { provide: getRepositoryToken(SalesRecordEntity), useFactory: mockRepository },
        { provide: getRepositoryToken(DailyWorklogEntity), useFactory: mockRepository },
        { provide: getRepositoryToken(MonthlyStatsEntity), useFactory: mockRepository },
      ],
    }).compile();

    service = module.get<RecordsService>(RecordsService);
    mealRepo = module.get(getRepositoryToken(DailyMealEntity));
    salesRepo = module.get(getRepositoryToken(SalesRecordEntity));
    worklogRepo = module.get(getRepositoryToken(DailyWorklogEntity));
    monthlyStatsRepo = module.get(getRepositoryToken(MonthlyStatsEntity));
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('getTodayMeal', () => {
    it('should return existing meal', async () => {
      mealRepo.findOne.mockResolvedValue(mockMeal);

      const result = await service.getTodayMeal();

      expect(result).toEqual(mockMeal);
      expect(mealRepo.findOne).toHaveBeenCalledWith({ where: { id: 1 } });
    });

    it('should create meal if not exists', async () => {
      mealRepo.findOne.mockResolvedValue(null);
      mealRepo.save.mockResolvedValue(mockMeal);

      const result = await service.getTodayMeal();

      expect(mealRepo.save).toHaveBeenCalled();
    });
  });

  describe('updateTodayMeal', () => {
    it('should update lunch', async () => {
      mealRepo.findOne.mockResolvedValue({ ...mockMeal });
      mealRepo.save.mockImplementation(async (meal) => meal as DailyMealEntity);

      const result = await service.updateTodayMeal({ lunch: '새 점심' });

      expect(result.lunch).toBe('새 점심');
    });

    it('should update dinner', async () => {
      mealRepo.findOne.mockResolvedValue({ ...mockMeal });
      mealRepo.save.mockImplementation(async (meal) => meal as DailyMealEntity);

      const result = await service.updateTodayMeal({ dinner: '새 저녁' });

      expect(result.dinner).toBe('새 저녁');
    });
  });

  describe('getSalesByDate', () => {
    it('should return sales for date', async () => {
      salesRepo.findOne.mockResolvedValue(mockSales);

      const result = await service.getSalesByDate('2025-01-15');

      expect(result).toEqual(mockSales);
      expect(salesRepo.findOne).toHaveBeenCalledWith({ where: { date: '2025-01-15' } });
    });

    it('should return null if not found', async () => {
      salesRepo.findOne.mockResolvedValue(null);

      const result = await service.getSalesByDate('2025-01-16');

      expect(result).toBeNull();
    });
  });

  describe('updateSales', () => {
    it('should update existing sales', async () => {
      salesRepo.findOne.mockResolvedValue({ ...mockSales });
      salesRepo.save.mockImplementation(async (sales) => sales as SalesRecordEntity);

      const result = await service.updateSales('2025-01-15', {
        totalKg: 1000,
        totalVehicles: 25,
      });

      expect(result.totalKg).toBe(1000);
      expect(result.totalVehicles).toBe(25);
    });

    it('should create new sales if not exists', async () => {
      salesRepo.findOne.mockResolvedValue(null);
      salesRepo.create.mockReturnValue({ date: '2025-01-16' } as SalesRecordEntity);
      salesRepo.save.mockImplementation(async (sales) => sales as SalesRecordEntity);

      const result = await service.updateSales('2025-01-16', {
        totalKg: 500,
        totalVehicles: 10,
      });

      expect(salesRepo.create).toHaveBeenCalledWith({ date: '2025-01-16' });
    });
  });

  describe('getWorklogByDate', () => {
    it('should return worklog for date', async () => {
      worklogRepo.findOne.mockResolvedValue(mockWorklog);

      const result = await service.getWorklogByDate('2025-01-15');

      expect(result).toEqual(mockWorklog);
    });
  });

  describe('addTTInOut', () => {
    it('should add TT in/out record', async () => {
      worklogRepo.findOne.mockResolvedValue({ ...mockWorklog, ttInOutRecords: [] });
      worklogRepo.save.mockImplementation(async (w) => w as DailyWorklogEntity);

      const result = await service.addTTInOut('2025-01-15', {
        record: { time: '11:00', description: '새 입고' },
      });

      expect(result.ttInOutRecords).toHaveLength(1);
      expect(result.ttInOutRecords[0].description).toBe('새 입고');
    });
  });

  describe('deleteTTInOut', () => {
    it('should delete TT in/out record by index', async () => {
      worklogRepo.findOne.mockResolvedValue({
        ...mockWorklog,
        ttInOutRecords: [
          { time: '09:00', description: '기록1' },
          { time: '10:00', description: '기록2' },
        ],
      });
      worklogRepo.save.mockImplementation(async (w) => w as DailyWorklogEntity);

      const result = await service.deleteTTInOut('2025-01-15', 0);

      expect(result.ttInOutRecords).toHaveLength(1);
      expect(result.ttInOutRecords[0].description).toBe('기록2');
    });
  });

  describe('getMonthlyPressureStats', () => {
    it('should calculate average pressure', async () => {
      worklogRepo.find.mockResolvedValue([
        {
          ...mockWorklog,
          ttChangeRecords: [
            { time: '10:00', direction: 'A→B', meterValue: 100, monthlyIndex: 1, pressureBefore: 50 },
            { time: '11:00', direction: 'B→A', meterValue: 100, monthlyIndex: 2, pressureBefore: 60 },
          ],
        },
      ]);

      const result = await service.getMonthlyPressureStats(2025, 1);

      expect(result.recordCount).toBe(2);
      expect(result.averagePressure).toBe(55); // (50 + 60) / 2
    });

    it('should return 0 if no records', async () => {
      worklogRepo.find.mockResolvedValue([]);

      const result = await service.getMonthlyPressureStats(2025, 1);

      expect(result.recordCount).toBe(0);
      expect(result.averagePressure).toBe(0);
    });
  });

  describe('getMonthlySalesStats', () => {
    it('should calculate monthly sales stats', async () => {
      salesRepo.find.mockResolvedValue([
        { ...mockSales, totalKg: 100, totalVehicles: 10 },
        { ...mockSales, totalKg: 200, totalVehicles: 20 },
      ]);

      const result = await service.getMonthlySalesStats(2025, 1);

      expect(result.totalKg).toBe(300);
      expect(result.totalVehicles).toBe(30);
      expect(result.recordCount).toBe(2);
      expect(result.dailyAvgKg).toBe(150);
      expect(result.dailyAvgVehicles).toBe(15);
    });
  });

  describe('searchNotes', () => {
    it('should search notes with keyword', async () => {
      worklogRepo.find.mockResolvedValue([
        { ...mockWorklog, notes: '점검 완료' },
        { ...mockWorklog, notes: '정기 점검 예정' },
      ]);

      const result = await service.searchNotes('점검');

      expect(result).toHaveLength(2);
      expect(result[0].notes).toContain('점검');
    });
  });
});
