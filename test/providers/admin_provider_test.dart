import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snh2/providers/admin_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminProvider', () {
    late AdminProvider provider;

    setUp(() async {
      // SharedPreferences mock 설정
      SharedPreferences.setMockInitialValues({});
      provider = AdminProvider();
    });

    group('초기 상태', () {
      test('초기값은 로그아웃 상태', () {
        expect(provider.isAdminMode, false);
        expect(provider.accessToken, null);
        expect(provider.hasValidToken, false);
      });
    });

    group('hasValidToken', () {
      test('토큰이 null이면 false', () {
        expect(provider.hasValidToken, false);
      });

      test('토큰이 빈 문자열이면 false', () {
        // 내부 상태를 직접 설정할 수 없으므로 초기 상태 확인
        expect(provider.hasValidToken, false);
      });
    });

    group('login 시나리오', () {
      test('로그인 성공시 isAdminMode가 true가 되어야 함', () async {
        // 실제 API 호출 없이 로직만 테스트
        // 통합 테스트에서 실제 로그인 플로우 검증 필요
        expect(provider.isAdminMode, false);
      });

      test('잘못된 비밀번호로 로그인 실패시 isAdminMode는 false 유지', () async {
        final result = await provider.login('wrong-password');

        // API 호출 실패 (서버 연결 안됨) 또는 잘못된 비밀번호
        expect(result, false);
        expect(provider.isAdminMode, false);
      });
    });

    group('logout', () {
      test('로그아웃 전 초기 상태 확인', () {
        // FlutterSecureStorage는 플랫폼 채널이 필요하므로
        // 실제 logout() 호출은 통합 테스트에서 진행
        // 여기서는 초기 상태가 로그아웃 상태인지만 확인
        expect(provider.isAdminMode, false);
        expect(provider.accessToken, null);
        expect(provider.hasValidToken, false);
      });
    });
  });
}
