import { ExecutionContext } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtAuthGuard } from './jwt-auth.guard';

describe('JwtAuthGuard', () => {
  let guard: JwtAuthGuard;

  const mockConfigService = {
    get: jest.fn(),
  };

  beforeEach(() => {
    guard = new JwtAuthGuard(mockConfigService as unknown as ConfigService);
    jest.clearAllMocks();
  });

  describe('canActivate', () => {
    it('Guard가 정의되어 있어야 함', () => {
      expect(guard).toBeDefined();
    });

    it('AuthGuard를 상속받아야 함', () => {
      expect(guard.canActivate).toBeDefined();
    });
  });
});
