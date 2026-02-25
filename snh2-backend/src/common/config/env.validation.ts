/**
 * 환경변수 검증
 * 서버 시작 전 필수 환경변수가 설정되어 있는지 확인
 */

interface EnvConfig {
  required: string[];
  optional: string[];
}

const envConfig: EnvConfig = {
  required: [
    'DATABASE_URL',       // PostgreSQL 연결 문자열
    'JWT_SECRET',         // JWT 서명 키
    'ADMIN_PASSWORD',     // 관리자 로그인 비밀번호
  ],
  optional: [
    'PORT',               // 서버 포트 (기본값: 3000)
    'NODE_ENV',           // 환경 (development/production)
    'ENABLE_AUTH_GUARD',  // 인증 Guard 활성화 여부
  ],
};

export function validateEnv(): void {
  const missing: string[] = [];
  const warnings: string[] = [];

  // 필수 환경변수 확인
  for (const key of envConfig.required) {
    if (!process.env[key]) {
      missing.push(key);
    }
  }

  // 필수 환경변수 누락 시 에러
  if (missing.length > 0) {
    console.error('❌ Missing required environment variables:');
    missing.forEach((key) => console.error(`   - ${key}`));
    console.error('\nPlease set these variables before starting the server.');
    process.exit(1);
  }

  // 선택 환경변수 경고
  for (const key of envConfig.optional) {
    if (!process.env[key]) {
      warnings.push(key);
    }
  }

  if (warnings.length > 0) {
    console.warn('⚠️  Optional environment variables not set:');
    warnings.forEach((key) => console.warn(`   - ${key} (using default)`));
  }

  console.log('✅ Environment validation passed');
}
