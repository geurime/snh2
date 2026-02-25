import 'package:flutter_test/flutter_test.dart';
import 'package:snh2/services/hydrogen_api.dart';

void main() {
  group('HydrogenApiService', () {
    late HydrogenApiService apiService;

    setUp(() {
      apiService = HydrogenApiService();
    });

    group('싱글톤 패턴', () {
      test('동일한 인스턴스 반환', () {
        final instance1 = HydrogenApiService();
        final instance2 = HydrogenApiService();

        expect(identical(instance1, instance2), true);
      });
    });

    group('토큰 관리', () {
      test('초기 상태에서 hasToken은 false', () {
        // 새 테스트를 위해 토큰 초기화
        apiService.setAccessToken(null);
        expect(apiService.hasToken, false);
      });

      test('setAccessToken으로 토큰 설정 후 hasToken은 true', () {
        apiService.setAccessToken('test-token');
        expect(apiService.hasToken, true);
      });

      test('빈 문자열 토큰은 hasToken false', () {
        apiService.setAccessToken('');
        expect(apiService.hasToken, false);
      });

      test('null 토큰은 hasToken false', () {
        apiService.setAccessToken('test-token');
        expect(apiService.hasToken, true);

        apiService.setAccessToken(null);
        expect(apiService.hasToken, false);
      });
    });

    group('ChargerStatus enum', () {
      test('displayName 반환', () {
        expect(ChargerStatus.operating.displayName, '정상');
        expect(ChargerStatus.broken.displayName, '고장');
        expect(ChargerStatus.maintenance.displayName, '점검중');
      });

      test('fromString 파싱', () {
        expect(ChargerStatus.fromString('operating'), ChargerStatus.operating);
        expect(ChargerStatus.fromString('broken'), ChargerStatus.broken);
        expect(ChargerStatus.fromString('maintenance'), ChargerStatus.maintenance);
        expect(ChargerStatus.fromString('unknown'), ChargerStatus.operating);
      });
    });

    group('CarWashStatus enum', () {
      test('fromString 파싱', () {
        expect(CarWashStatus.fromString('operating'), CarWashStatus.operating);
        expect(CarWashStatus.fromString('maintenance'), CarWashStatus.maintenance);
        expect(CarWashStatus.fromString('closed'), CarWashStatus.closed);
        expect(CarWashStatus.fromString('unknown'), CarWashStatus.operating);
      });
    });

    group('TTStatus enum', () {
      test('fromString 파싱', () {
        expect(TTStatus.fromString('empty'), TTStatus.empty);
        expect(TTStatus.fromString('standby'), TTStatus.standby);
        expect(TTStatus.fromString('inUse'), TTStatus.inUse);
        expect(TTStatus.fromString('unknown'), TTStatus.empty);
      });
    });

    group('TTData', () {
      test('fromJson 파싱', () {
        final json = {
          'schedules': ['09:00', '12:00', '15:00'],
          'totalCount': 3,
          'currentIndex': 1,
        };

        final ttData = TTData.fromJson(json);

        expect(ttData.schedules, ['09:00', '12:00', '15:00']);
        expect(ttData.totalCount, 3);
        expect(ttData.currentIndex, 1);
      });

      test('빈 schedules 처리', () {
        final json = {
          'schedules': null,
          'totalCount': 0,
          'currentIndex': 0,
        };

        final ttData = TTData.fromJson(json);

        expect(ttData.schedules, []);
        expect(ttData.totalCount, 0);
      });
    });
  });
}
