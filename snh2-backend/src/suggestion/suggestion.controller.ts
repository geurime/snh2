import { Controller, Post, Get, Body } from '@nestjs/common';
import { SuggestionService } from './suggestion.service';

class CreateSuggestionDto {
  content: string;
}

@Controller('suggestion')
export class SuggestionController {
  constructor(private readonly suggestionService: SuggestionService) {}

  @Post()
  async create(@Body() dto: CreateSuggestionDto) {
    return this.suggestionService.create(dto.content);
  }

  @Get()
  async findAll() {
    return this.suggestionService.findAll();
  }
}
