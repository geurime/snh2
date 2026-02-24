import { Controller, Get, Patch, Post, Body } from '@nestjs/common';
import { StationService } from './station.service';
import { UpdateChargerDto, UpdateCarWashDto, UpdateAnnouncementDto, TTIncomingDto, TTChangeDto, SetTTStatusDto } from './dto/update-station.dto';

@Controller('station')
export class StationController {
  constructor(private readonly stationService: StationService) {}

  @Get('status')
  async getStatus() {
    return this.stationService.getStatus();
  }

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

  // T/T 입고
  @Post('tt/incoming')
  async ttIncoming(@Body() dto: TTIncomingDto) {
    return this.stationService.ttIncoming(dto);
  }

  // T/T 교체
  @Post('tt/change')
  async ttChange(@Body() dto: TTChangeDto) {
    return this.stationService.ttChange(dto);
  }

  // T/T 상태 직접 설정
  @Patch('tt/status')
  async setTTStatus(@Body() dto: SetTTStatusDto) {
    return this.stationService.setTTStatus(dto.ttAStatus, dto.ttBStatus);
  }
}
