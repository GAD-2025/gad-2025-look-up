import 'package:flutter/material.dart';
import 'start_page.dart';
import 'send_page.dart';
import 'my_log_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

void main() {
  KakaoSdk.init(nativeAppKey: '03033934ad0bba787529944420a0e059');
  runApp(const LookupApp());
}

class LookupApp extends StatelessWidget {
  const LookupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const StartPage(),
    );
  }
}

// -------------------------------------------------------------
//                 ⭐ 탭 기반 메인 화면 LookupMain
// -------------------------------------------------------------
class LookupMain extends StatefulWidget {
  const LookupMain({super.key});

  @override
  State<LookupMain> createState() => _LookupMainState();
}

class _LookupMainState extends State<LookupMain> {
  int _selectedIndex = 0;

  // 피드 상태 ------------------------------
  String _currentLocation = "위치 불러오는 중...";
  String? _emoji;
  bool _hasFeed = false;

  int _remainingSeconds = 0;
  bool _showTimer = false;
  bool _isTimeout = false;

  // 플로팅 버튼 상태 (피드/마이로그 둘 다 공유)
  bool _isButtonDisabled = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  // 위치 불러오기 ------------------------------------------------
  Future<void> _loadLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _currentLocation = "위치 서비스 꺼짐");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _currentLocation = "권한 거부됨");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _currentLocation = "권한 영구 거부됨");
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );

    final place = placemarks.first;
    final location = "${place.locality ?? ''} ${place.subLocality ?? ''}"
        .trim();

    setState(() {
      _currentLocation = location.isNotEmpty ? location : "위치 정보 없음";
    });
  }

  // SendPage 열기 ------------------------------------------------
  Future<void> _openSendPage() async {
    if (_isButtonDisabled) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SendPage()),
    );

    if (result != null && result is String) {
      // 알림 전송됨!
      setState(() {
        _emoji = result;
        _hasFeed = true;

        // 타이머 작동
        _remainingSeconds = 180;
        _showTimer = true;
        _isTimeout = false;

        // 버튼 비활성
        _isButtonDisabled = true;
      });

      _showToast();
      _startTimer();
    }
  }

  // -------------------------------------------------------------
  // 타이머
  // -------------------------------------------------------------
  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));

      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
        return true;
      }

      setState(() {
        _isTimeout = true;
        _showTimer = true;
      });

      return false;
    });
  }

  String _format(int sec) =>
      "${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}";

  // -------------------------------------------------------------
  // 전송 완료 토스트
  // -------------------------------------------------------------
  void _showToast() {
    OverlayEntry overlay = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 120,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFBFBF), width: 1.3),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.check_rounded, size: 20, color: Colors.black87),
                  SizedBox(width: 10),
                  Text(
                    "전송 완료!",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
    Future.delayed(const Duration(seconds: 3), () => overlay.remove());
  }

  // -------------------------------------------------------------
  // UI 구성
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildFeedPage(),
      const MyLogPage(), // 타이머 없음
    ];

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 140,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 8),
          child: Image.asset('assets/logo.png', height: 38),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 8),
            child: Image.asset('assets/icons/bell_icon.png', width: 26),
          ),
        ],
      ),

      body: IndexedStack(index: _selectedIndex, children: pages),

      floatingActionButton: FloatingActionButton(
        backgroundColor: _isButtonDisabled ? Colors.grey : Colors.black,
        shape: const CircleBorder(),
        onPressed: _isButtonDisabled ? null : _openSendPage,
        child: Image.asset("assets/lookup_icon.png", width: 35),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 하단 탭
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem("피드", 0, "assets/icons/home_icon.png"),
            const SizedBox(width: 50),
            _navItem("마이로그", 1, "assets/icons/person_icon.png"),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 네비게이션 아이템
  // -------------------------------------------------------------
  Widget _navItem(String label, int index, String icon) {
    final selected = _selectedIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            icon,
            width: 22,
            color: selected ? Colors.black : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 피드 페이지 (타이머 포함)
  // -------------------------------------------------------------
  Widget _buildFeedPage() {
    // 1) 아직 알림을 보내지 않아 피드가 없을 때
    if (!_hasFeed) {
      return Stack(
        children: [
          // 중앙 카드 + 텍스트
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 26,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentLocation,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "아직 피드가 없어요",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "먼저 알림을 보내 주변 풍경을 공유해봐요!",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),

          // 플로팅 버튼 위 말풍선
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(child: _buildBubble()),
          ),
        ],
      );
    }

    // 2) 알림을 보낸 뒤, 타이머가 있는 피드 화면
    return Stack(
      children: [
        // 위치 + 이모지 태그
        Positioned(
          left: 20,
          top: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${_emoji ?? ''} $_currentLocation",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),

        // 타이머
        if (_showTimer)
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isTimeout ? const Color(0xFFEDEDED) : Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 16,
                      color: _isTimeout ? Colors.grey : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isTimeout ? "TIME OUT" : _format(_remainingSeconds),
                      style: TextStyle(
                        color: _isTimeout ? Colors.grey : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 🔥 타이머 아래 말풍선
        if (_showTimer)
          Positioned(
            top: 120, // 타이머 바로 아래 적당한 위치 (필요하면 숫자 살짝 조절해도 돼!)
            left: 0,
            right: 0,
            child: Center(child: _buildTimerBubble()),
          ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 빈 피드일 때 플로팅 버튼 위 말풍선
  // -------------------------------------------------------------
  Widget _buildBubble() {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            "내 주변 1km 내 사용자에게\n룩업 알림 보내기",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Positioned(
          bottom: -12,
          child: CustomPaint(
            size: const Size(20, 12),
            painter: _BubbleTailPainter(),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 타이머 아래 말풍선
  // -------------------------------------------------------------
  Widget _buildTimerBubble() {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // 꼬리 (위쪽을 향함)
        Positioned(
          top: -10,
          child: CustomPaint(
            size: const Size(20, 10),
            painter: _BubbleUpTailPainter(),
          ),
        ),
        // 말풍선 본체
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            "아직 게시물이 없어요!\n가장 먼저 풍경을 촬영해 보세요",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// 말풍선 꼬리 (아래로 향한 꼬리 - 플로팅 버튼 위 말풍선)
// -------------------------------------------------------------
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// -------------------------------------------------------------
// 타이머 아래 말풍선 꼬리 (위로 향한 꼬리)
// -------------------------------------------------------------
class _BubbleUpTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0) // 위 중앙
      ..lineTo(0, size.height) // 왼쪽 아래
      ..lineTo(size.width, size.height) // 오른쪽 아래
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
