import { Controller, Get, Patch, Post, Body, UseGuards } from '@nestjs/common';
import { StationService } from './station.service';
import { UpdateChargerDto, UpdateCarWashDto, UpdateAnnouncementDto, TTIncomingDto, TTChangeDto, SetTTStatusDto } from './dto/update-station.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('station')
export class StationController {
  constructor(private readonly stationService: StationService) {}

  // 공개 API - 인증 불필요
  @Get('status')
  async getStatus() {
    return this.stationService.getStatus();
  }

  // 관리자 전용 API - 인증 필요
  @UseGuards(JwtAuthGuard)
  @Patch('charger')
  async updateCharger(@Body() dto: UpdateChargerDto) {
    return this.stationService.updateCharger(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('carwash')
  async updateCarWash(@Body() dto: UpdateCarWashDto) {
    return this.stationService.updateCarWash(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('announcement')
  async updateAnnouncement(@Body() dto: UpdateAnnouncementDto) {
    return this.stationService.updateAnnouncement(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post('tt/incoming')
  async ttIncoming(@Body() dto: TTIncomingDto) {
    return this.stationService.ttIncoming(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post('tt/change')
  async ttChange(@Body() dto: TTChangeDto) {
    return this.stationService.ttChange(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('tt/status')
  async setTTStatus(@Body() dto: SetTTStatusDto) {
    return this.stationService.setTTStatus(dto.ttAStatus, dto.ttBStatus);
  }
}
