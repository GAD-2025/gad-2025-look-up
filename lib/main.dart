import 'send_page.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(const LookupApp());
}

class LookupApp extends StatelessWidget {
  const LookupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LookupHomePage(),
    );
  }
}

class LookupHomePage extends StatefulWidget {
  const LookupHomePage({super.key});

  @override
  State<LookupHomePage> createState() => _LookupHomePageState();
}

class _LookupHomePageState extends State<LookupHomePage> {
  String _currentLocation = '위치 불러오는 중...';
  String? _emoji; // 이모티콘 저장
  bool _hasFeed = false; // ✅ 피드 전송 여부

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _currentLocation = '위치 서비스 꺼짐');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _currentLocation = '권한 거부됨');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _currentLocation = '권한 영구 거부됨');
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    Placemark place = placemarks.first;

    String location = '${place.locality ?? ''} ${place.subLocality ?? ''}'
        .trim();

    setState(() {
      _currentLocation = location.isNotEmpty ? location : '위치 정보 없음';
    });
  }

  // SendPage에서 이모티콘 받아오기
  Future<void> _openSendPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SendPage()),
    );

    if (result != null && result is String && result.isNotEmpty) {
      setState(() {
        _emoji = result;
        _hasFeed = true; // ✅ 피드 전송 완료
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 140,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 8.0),
          child: Image.asset(
            'assets/logo.png',
            height: 38,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.black87,
            ),
            onPressed: () {},
          ),
        ],
      ),

      // 하단 네비게이션
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home, color: Colors.black),
                  Text('피드', style: TextStyle(fontSize: 12)),
                ],
              ),
              SizedBox(width: 50),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline, color: Colors.grey),
                  Text(
                    '마이로그',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openSendPage,
        backgroundColor: Colors.black,
        elevation: 6,
        shape: const CircleBorder(),
        child: Image.asset('assets/lookup_icon.png', width: 30, height: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ✅ 본문 내용
      body: _hasFeed ? _buildFeedView() : _buildEmptyView(),
    );
  }

  // ✅ 피드가 없을 때 (기존 화면)
  Widget _buildEmptyView() {
    return Center(
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
                const Icon(Icons.location_on, color: Colors.grey, size: 26),
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
            '아직 피드가 없어요',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            '먼저 알림을 보내 주변 풍경을 공유해봐요!',
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 80),
          _buildBubble(),
        ],
      ),
    );
  }

  // ✅ 전송 완료 후 피드 표시 화면
  Widget _buildFeedView() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 16),
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Text(
            '${_emoji ?? ''} $_currentLocation',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // 💬 회색 말풍선
  Widget _buildBubble() {
    return Stack(
      alignment: Alignment.bottomCenter,
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
            '내 주변 1km 내 사용자에게\n룩업 알림 보내기',
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
          bottom: -8,
          child: CustomPaint(
            size: const Size(20, 10),
            painter: _BubbleTailPainter(),
          ),
        ),
      ],
    );
  }
}

// 🎨 회색 말풍선 꼬리
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
