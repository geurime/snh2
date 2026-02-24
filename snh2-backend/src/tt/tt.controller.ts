import { Controller, Get, Patch, Put, Body, Param } from '@nestjs/common';
import { TTService } from './tt.service';
import { UpdateTTStatusDto, UpdateTTScheduleDto } from './dto/update-tt.dto';

@Controller('tt')
export class TTController {
  constructor(private readonly ttService: TTService) {}

  @Get('today')
  async getTodayStatus() {
    return this.ttService.getTodayStatus();
  }

  @Get(':date')
  async getStatusByDate(@Param('date') date: string) {
    return this.ttService.getStatusByDate(date);
  }

  @Patch('today')
  async updateTodayStatus(@Body() dto: UpdateTTStatusDto) {
    return this.ttService.updateTodayStatus(dto);
  }

  @Put('schedule')
  async updateSchedule(@Body() dto: UpdateTTScheduleDto) {
    return this.ttService.updateSchedule(dto);
  }

  @Put('schedule/:date')
  async updateScheduleByDate(
    @Param('date') date: string,
    @Body() dto: UpdateTTScheduleDto,
  ) {
    return this.ttService.updateScheduleByDate(date, dto.schedules);
  }
}
