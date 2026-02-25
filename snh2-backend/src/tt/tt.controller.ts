import { Controller, Get, Patch, Put, Body, Param, UseGuards } from '@nestjs/common';
import { TTService } from './tt.service';
import { UpdateTTStatusDto, UpdateTTScheduleDto } from './dto/update-tt.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

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
  @UseGuards(JwtAuthGuard)
  @Patch('today')
  async updateTodayStatus(@Body() dto: UpdateTTStatusDto) {
    return this.ttService.updateTodayStatus(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Put('schedule')
  async updateSchedule(@Body() dto: UpdateTTScheduleDto) {
    return this.ttService.updateSchedule(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Put('schedule/:date')
  async updateScheduleByDate(
    @Param('date') date: string,
    @Body() dto: UpdateTTScheduleDto,
  ) {
    return this.ttService.updateScheduleByDate(date, dto.schedules);
  }
}
