import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'constants/colors.dart';
import 'constants/typography.dart';
import 'providers/station_provider.dart';
import 'providers/admin_provider.dart';
import 'constants/spacing.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'widgets/pressable.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'sales_closing',
  '마감 알림',
  importance: Importance.high,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 포그라운드 알림 표시 (iOS)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Android 로컬 알림 초기화
  await _localNotifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_androidChannel);

  // Android 포그라운드 알림 처리
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StationProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '성남수소충전소',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // UI 전체 기본 서체. 화면마다 지정하지 않는다.
        fontFamily: AppText.fontFamily,
        scaffoldBackgroundColor: AppColors.gray100,
        colorScheme: const ColorScheme.light(
          primary: AppColors.orange,
        ),
      ),
      // 스플래시를 두지 않는다 — 하루에도 몇 번씩 열어 5초 보고 나가는 앱이라
      // 1초 대기가 매번 겪는 지연이 된다. 브랜드는 앱 아이콘이 이미 각인한다.
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isAdminMode = context.watch<AdminProvider>().isAdminMode;

    // 손님 화면은 한 장이라 전환할 것이 없다.
    if (!isAdminMode) {
      _currentIndex = 0;
      return const Scaffold(body: HomeScreen());
    }

    // 탭바가 아니라 모드 전환 스위치다 — 관리자에게만, 임시로 얹힌다.
    // 그래서 화면 폭을 차지하는 고정 바 대신 떠 있는 세그먼트를 쓴다.
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: const [
              HomeScreen(bottomInset: _ModeSwitch.reservedHeight),
              AdminScreen(bottomInset: _ModeSwitch.reservedHeight),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.xxl),
                child: Center(
                  child: _ModeSwitch(
                    currentIndex: _currentIndex,
                    onSelect: (index) => setState(() => _currentIndex = index),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 인디케이터가 옆으로 미끄러지며 붙는다. 칸마다 배경을 켜고 끄면 두 개가
/// 깜빡이는 것으로 보이지만, 하나가 이동하면 "여기서 저기로 옮겼다"가 된다.
class _ModeSwitch extends StatelessWidget {
  /// 스위치가 마지막 콘텐츠를 가리지 않도록 각 화면이 비워둘 아래 여백.
  static const reservedHeight = 92.0;

  static const _segmentWidth = 92.0;
  static const _segmentHeight = 44.0;
  static const _pad = AppSpace.xs;

  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _ModeSwitch({required this.currentIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_pad),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppShadow.floating,
      ),
      child: SizedBox(
        width: _segmentWidth * 2,
        height: _segmentHeight,
        child: Stack(
          children: [
            AnimatedAlign(
              duration: AppMotion.of(context, AppMotion.snap),
              curve: AppMotion.snapCurve,
              alignment:
                  currentIndex == 0 ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: _segmentWidth,
                height: _segmentHeight,
                decoration: BoxDecoration(
                  color: AppColors.orangeTint,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              children: [
                _Segment(
                  label: '현황',
                  isSelected: currentIndex == 0,
                  onTap: () => onSelect(0),
                ),
                _Segment(
                  label: '관리',
                  isSelected: currentIndex == 1,
                  onTap: () => onSelect(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.94,
      onTap: onTap,
      child: SizedBox(
        width: _ModeSwitch._segmentWidth,
        height: _ModeSwitch._segmentHeight,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.curve,
            style: AppText.body.copyWith(
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.orangeText : AppColors.gray600,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
