import { Controller, Get, Patch, Body, Param } from '@nestjs/common';
import { TTService } from './tt.service';
import { UpdateTTStatusDto } from './dto/update-tt.dto';

@Controller('tt')
export class TTController {
  constructor(private readonly ttService: TTService) {}

  // 공개 API
  @Get('today')
  async getTodayStatus() {
    return this.ttService.getTodayStatus();
  }

  @Get(':date')
  async getStatusByDate(@Param('date') date: string) {
    return this.ttService.getStatusByDate(date);
  }

  // 관리자 전용 API

  @Patch('today')
  async updateTodayStatus(@Body() dto: UpdateTTStatusDto) {
    return this.ttService.updateTodayStatus(dto);
  }


}
