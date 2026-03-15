import { Controller, Post, Delete, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { NotificationService } from '../notification/notification.service';

@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private notificationService: NotificationService,
  ) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() loginDto: LoginDto): Promise<{ access_token: string }> {
    return this.authService.login(loginDto.password);
  }

  @Post('fcm-token')
  @HttpCode(HttpStatus.OK)
  async registerFcmToken(@Body() body: { token: string }) {
    await this.notificationService.registerToken(body.token);
    return { success: true };
  }

  @Delete('fcm-token')
  @HttpCode(HttpStatus.OK)
  async unregisterFcmToken(@Body() body: { token: string }) {
    await this.notificationService.unregisterToken(body.token);
    return { success: true };
  }
}
