import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import { validateEnv } from './common/config/env.validation';

async function bootstrap() {
  // 환경변수 검증 (앱 생성 전)
  validateEnv();

  const app = await NestFactory.create(AppModule);

  // Validation
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
    }),
  );

  // CORS 설정 (화이트리스트 방식)
  const allowedOrigins = [
    'https://snh2-production.up.railway.app',
    ...(process.env.NODE_ENV === 'development'
      ? ['http://localhost:3000', 'http://localhost:8080']
      : []),
  ];

  app.enableCors({
    origin: (origin, callback) => {
      // 모바일 앱은 origin이 없음 - 허용
      if (!origin) {
        return callback(null, true);
      }
      // 화이트리스트 체크
      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
  });

  // API 프리픽스
  app.setGlobalPrefix('api');

  const port = process.env.PORT || 3000;
  await app.listen(port);

  console.log(`Server is running on port ${port}`);
}
bootstrap();
