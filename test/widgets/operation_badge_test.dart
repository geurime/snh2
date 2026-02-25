import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snh2/screens/home/widgets/operation_badge.dart';
import 'package:snh2/services/hydrogen_api.dart';

void main() {
  group('OperationBadge', () {
    testWidgets('shows loading state correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OperationBadge(
              status: null,
              isLoading: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('확인중'), findsOneWidget);
    });

    testWidgets('shows operating status with green dot', (tester) async {
      final status = IntegratedStatus(
        publicData: PublicData(
          operationStatus: '운영중',
          isOperating: true,
        ),
        station: StationData(
          chargerA: ChargerStatus.operating,
          chargerB: ChargerStatus.operating,
          carWashStatus: CarWashStatus.operating,
          ttAStatus: TTStatus.empty,
          ttBStatus: TTStatus.empty,
        ),
        tt: TTData(totalCount: 0, currentIndex: 0, schedules: []),
        tomorrowTT: TomorrowTTData(schedules: []),
        meal: MealData(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OperationBadge(
              status: status,
              isLoading: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('운영중'), findsOneWidget);
    });

    testWidgets('shows closed status with red dot', (tester) async {
      final status = IntegratedStatus(
        publicData: PublicData(
          operationStatus: '운영종료',
          isOperating: false,
        ),
        station: StationData(
          chargerA: ChargerStatus.operating,
          chargerB: ChargerStatus.operating,
          carWashStatus: CarWashStatus.operating,
          ttAStatus: TTStatus.empty,
          ttBStatus: TTStatus.empty,
        ),
        tt: TTData(totalCount: 0, currentIndex: 0, schedules: []),
        tomorrowTT: TomorrowTTData(schedules: []),
        meal: MealData(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OperationBadge(
              status: status,
              isLoading: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('운영종료'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OperationBadge(
              status: null,
              isLoading: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OperationBadge));
      expect(tapped, isTrue);
    });

    testWidgets('shows default text when status is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OperationBadge(
              status: null,
              isLoading: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('확인중'), findsOneWidget);
    });
  });
}
