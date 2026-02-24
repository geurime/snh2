import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThanOrEqual } from 'typeorm';
import { SuggestionEntity } from '../entities';

@Injectable()
export class SuggestionService {
  constructor(
    @InjectRepository(SuggestionEntity)
    private readonly suggestionRepo: Repository<SuggestionEntity>,
  ) {}

  async create(content: string): Promise<SuggestionEntity> {
    const suggestion = this.suggestionRepo.create({ content });
    return this.suggestionRepo.save(suggestion);
  }

  async findAll(): Promise<SuggestionEntity[]> {
    // 최근 7일치만 조회
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    return this.suggestionRepo.find({
      where: {
        createdAt: MoreThanOrEqual(sevenDaysAgo),
      },
      order: { createdAt: 'DESC' },
    });
  }
}
