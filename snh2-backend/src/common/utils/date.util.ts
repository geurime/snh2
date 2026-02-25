/**
 * KST (한국 표준시) 날짜/시간 유틸리티
 * UTC+9 기준으로 날짜와 시간을 계산
 */

const KST_OFFSET_MINUTES = 9 * 60; // UTC+9

/**
 * 현재 KST 시간의 Date 객체 반환
 */
export function getKSTNow(): Date {
  const now = new Date();
  return new Date(now.getTime() + KST_OFFSET_MINUTES * 60 * 1000);
}

/**
 * KST 기준 오늘 날짜 (YYYY-MM-DD)
 * @param offsetDays 오늘 기준 일수 오프셋 (예: 1 = 내일, -1 = 어제)
 */
export function getKSTDate(offsetDays: number = 0): string {
  const kstTime = getKSTNow();
  if (offsetDays !== 0) {
    kstTime.setDate(kstTime.getDate() + offsetDays);
  }
  return kstTime.toISOString().split('T')[0];
}

/**
 * KST 기준 현재 시간 (HH:mm)
 */
export function getKSTTime(): string {
  const kstTime = getKSTNow();
  return kstTime.toISOString().split('T')[1].substring(0, 5);
}

/**
 * KST 기준 현재 시간이 영업시간인지 확인
 * @param startHour 영업 시작 시간 (기본 7시)
 * @param endHour 영업 종료 시간 (기본 20시)
 * @param endMinute 영업 종료 분 (기본 30분)
 */
export function isBusinessHours(
  startHour: number = 7,
  endHour: number = 20,
  endMinute: number = 30,
): boolean {
  const kstTime = getKSTNow();
  const hours = kstTime.getUTCHours();
  const minutes = kstTime.getUTCMinutes();

  if (hours < startHour) return false;
  if (hours > endHour) return false;
  if (hours === endHour && minutes > endMinute) return false;

  return true;
}

/**
 * 특정 월의 마지막 날짜 반환
 */
export function getLastDayOfMonth(year: number, month: number): number {
  return new Date(year, month, 0).getDate();
}
