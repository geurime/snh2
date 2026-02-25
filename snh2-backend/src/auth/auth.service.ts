import { Injectable, UnauthorizedException, InternalServerErrorException, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async validatePassword(password: string): Promise<boolean> {
    const adminPassword = this.configService.get<string>('ADMIN_PASSWORD');

    if (!adminPassword) {
      this.logger.error('ADMIN_PASSWORD is not configured');
      throw new InternalServerErrorException('Server configuration error');
    }

    return password === adminPassword;
  }

  async login(password: string): Promise<{ access_token: string }> {
    const isValid = await this.validatePassword(password);

    if (!isValid) {
      this.logger.warn('Failed login attempt');
      throw new UnauthorizedException('Invalid password');
    }

    const payload = { role: 'admin' };
    const access_token = this.jwtService.sign(payload);

    this.logger.log('Admin login successful');

    return { access_token };
  }

  verifyToken(token: string): boolean {
    try {
      this.jwtService.verify(token);
      return true;
    } catch {
      return false;
    }
  }
}
