import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SuggestionEntity } from '../entities';
import { SuggestionService } from './suggestion.service';
import { SuggestionController } from './suggestion.controller';

@Module({
  imports: [TypeOrmModule.forFeature([SuggestionEntity])],
  controllers: [SuggestionController],
  providers: [SuggestionService],
})
export class SuggestionModule {}
