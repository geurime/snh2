import { Controller, Get, Patch, Post, Body } from '@nestjs/common';
import { StationService } from './station.service';
import { UpdateChargerDto, UpdateCarWashDto, UpdateAnnouncementDto, TTIncomingDto, TTChangeDto, SetTTStatusDto } from './dto/update-station.dto';

@Controller('station')
export class StationController {
  constructor(private readonly stationService: StationService) {}

  // 공개 API - 인증 불필요
  @Get('status')
  async getStatus() {
    return this.stationService.getStatus();
  }

  // 관리자 전용 API - 인증 필요
  @Patch('charger')
  async updateCharger(@Body() dto: UpdateChargerDto) {
    return this.stationService.updateCharger(dto);
  }

  @Patch('carwash')
  async updateCarWash(@Body() dto: UpdateCarWashDto) {
    return this.stationService.updateCarWash(dto);
  }

  @Patch('announcement')
  async updateAnnouncement(@Body() dto: UpdateAnnouncementDto) {
    return this.stationService.updateAnnouncement(dto);
  }

  @Post('tt/incoming')
  async ttIncoming(@Body() dto: TTIncomingDto) {
    return this.stationService.ttIncoming(dto);
  }

  @Post('tt/change')
  async ttChange(@Body() dto: TTChangeDto) {
    return this.stationService.ttChange(dto);
  }

  @Patch('tt/status')
  async setTTStatus(@Body() dto: SetTTStatusDto) {
    return this.stationService.setTTStatus(dto.ttAStatus, dto.ttBStatus);
  }
}
