import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';

describe('AuthService', () => {
  let service: AuthService;
  let jwtService: JwtService;
  let configService: ConfigService;

  const mockJwtService = {
    sign: jest.fn().mockReturnValue('mock-jwt-token'),
    verify: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: JwtService, useValue: mockJwtService },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    jwtService = module.get<JwtService>(JwtService);
    configService = module.get<ConfigService>(ConfigService);

    jest.clearAllMocks();
  });

  describe('validatePassword', () => {
    it('올바른 비밀번호면 true 반환', async () => {
      mockConfigService.get.mockReturnValue('correct-password');

      const result = await service.validatePassword('correct-password');

      expect(result).toBe(true);
    });

    it('틀린 비밀번호면 false 반환', async () => {
      mockConfigService.get.mockReturnValue('correct-password');

      const result = await service.validatePassword('wrong-password');

      expect(result).toBe(false);
    });

    it('ADMIN_PASSWORD 미설정시 에러 발생', async () => {
      mockConfigService.get.mockReturnValue(undefined);

      await expect(service.validatePassword('any')).rejects.toThrow(
        'Server configuration error',
      );
    });
  });

  describe('login', () => {
    it('올바른 비밀번호로 로그인시 JWT 토큰 반환', async () => {
      mockConfigService.get.mockReturnValue('correct-password');

      const result = await service.login('correct-password');

      expect(result).toHaveProperty('access_token');
      expect(result.access_token).toBe('mock-jwt-token');
      expect(mockJwtService.sign).toHaveBeenCalledWith({ role: 'admin' });
    });

    it('틀린 비밀번호로 로그인시 UnauthorizedException 발생', async () => {
      mockConfigService.get.mockReturnValue('correct-password');

      await expect(service.login('wrong-password')).rejects.toThrow(
        UnauthorizedException,
      );
    });
  });

  describe('verifyToken', () => {
    it('유효한 토큰이면 true 반환', () => {
      mockJwtService.verify.mockReturnValue({ role: 'admin' });

      const result = service.verifyToken('valid-token');

      expect(result).toBe(true);
    });

    it('유효하지 않은 토큰이면 false 반환', () => {
      mockJwtService.verify.mockImplementation(() => {
        throw new Error('Invalid token');
      });

      const result = service.verifyToken('invalid-token');

      expect(result).toBe(false);
    });
  });
});
