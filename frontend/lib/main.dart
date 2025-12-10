import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// 페이지
import 'start_page.dart';
import 'send_page.dart';
import 'pages/camera_page.dart';

// 모델
import 'models/post_model.dart';

void main() {
  KakaoSdk.init(nativeAppKey: '03033934ad0bba787529944420a0e059');
  runApp(const LookupApp());
}

class LookupApp extends StatelessWidget {
  const LookupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartPage(),
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
  String? _emoji;
  bool _hasFeed = false;

  int _remainingSeconds = 0;
  bool _showTimer = false;
  bool _isTimeout = false;
  bool _isButtonDisabled = false;

    // 🔥 피드 게시물 목록
    List<PostModel> feedPosts = [];

    // 🔥 게시물 추가 메서드
    void addPost(PostModel post) {
      setState(() {
        feedPosts.add(post);
      });
    }

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
        _hasFeed = true;
        _showTimer = true;
        _isTimeout = false;
        _remainingSeconds = 180;
        _isButtonDisabled = true;
      });

      _showSendComplete();
      _startTimer();
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
        return true;
      } else {
        setState(() {
          _isTimeout = true;
          _showTimer = true;
        });
        return false;
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes : $secs';
  }

  void _showSendComplete() {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 140,
        left: 24,
        right: 24,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBFBFBF), width: 1.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: const [
                Icon(Icons.check_rounded, color: Colors.black87, size: 20),
                SizedBox(width: 10),
                Text(
                  '전송 완료!',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  // 🔥 타이머 박스 = 카메라 이동 버튼
  Widget _buildTimerButton() {
    return GestureDetector(
      onTap: () async {
        if (_isTimeout) return; // TIME OUT이면 카메라 못 열게

        // 📸 CameraPage로 이동
        final newPost = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CameraPage()),
        );

        if (!mounted) return;

        // 📸 촬영 후 돌아온 PostModel이 있으면 피드에 추가
        if (newPost != null && newPost is PostModel) {
          addPost(newPost);
          setState(() {
            _showTimer = false; // 한 번 찍고 오면 타이머 숨기기 (원하는 대로 조절 가능)
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _isTimeout ? const Color(0xFFF1F1F1) : Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              color: _isTimeout ? Colors.grey : Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _isTimeout ? 'TIME OUT' : _formatTime(_remainingSeconds),
              style: TextStyle(
                color: _isTimeout ? Colors.grey : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
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
          Padding(
            padding: const EdgeInsets.only(right: 20.0, top: 8.0),
            child: IconButton(
              icon: Image.asset(
                'assets/icons/bell_icon.png',
                width: 27,
                height: 27,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: BottomAppBar(
          color: Colors.transparent,
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icons/home_icon.png',
                      width: 22,
                      height: 22,
                    ),
                    const Text(
                      '피드',
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(width: 50),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icons/person_icon.png',
                      width: 22,
                      height: 22,
                    ),
                    const Text(
                      '마이로그',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_isButtonDisabled) return;

          // ① SendPage 열기 → 이모지 선택
          final emoji = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SendPage()),
          );

          // 선택 안 하면 종료
          if (emoji == null || emoji is! String || emoji.isEmpty) return;

          // ② 피드 활성화 & 타이머 시작
          setState(() {
            _emoji = emoji;
            _hasFeed = true;
            _showTimer = true;
            _isTimeout = false;
            _remainingSeconds = 180;
          });

          // ❗ 카메라는 여기서 실행하지 않음
          // CameraPage는 타이머 버튼을 눌렀을 때 열려야 함!
        },
        backgroundColor: _isButtonDisabled ? Colors.grey : Colors.black,
        elevation: _isButtonDisabled ? 0 : 6,
        shape: const CircleBorder(),
        child: Image.asset('assets/lookup_icon.png', width: 35, height: 35),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      body: _hasFeed ? _buildFeedView() : _buildEmptyView(),
    );
  }

  // 피드 없음 화면
  Widget _buildEmptyView() {
    return Stack(
      children: [
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
            ],
          ),
        ),

        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(child: _buildBubble()),
        ),
      ],
    );
  }

  // 피드 화면 (타이머 + 말풍선)
  Widget _buildFeedView() {
  return Stack(
    children: [
      // 📌 1) 상단: 위치 + 이모지
      Padding(
        padding: const EdgeInsets.only(left: 20, top: 16),
        child: Align(
          alignment: Alignment.topLeft,
          child: _buildTimerButton(),
        ),
      ),

      // 📌 2) 타이머 박스 + 말풍선
      if (_showTimer)
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const SizedBox(height: 20),

                // 말풍선 (게시물이 없을 때만 노출)
                if (feedPosts.isEmpty)
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        top: -10,
                        child: CustomPaint(
                          size: const Size(20, 10),
                          painter: _BubbleUpTailPainter(),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
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
                          '아직 게시물이 없어요!\n가장 먼저 풍경을 촬영해보세요.',
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
                  ),
              ],
            ),
          ),
        ),

      // 📌 3) 전체 피드 그리드 (게시물이 있을 때만 표시)
      if (feedPosts.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 160), // 타이머 아래로 공간 확보
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: feedPosts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final post = feedPosts[index];

              return GestureDetector(
                onTap: () {
                  // 🔥 게시물 상세 페이지 이동 예정
                  print("게시물 클릭: ${post.nickname}");
                },
                child: Stack(
                  children: [
                    // 이미지
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(post.imagePath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),

                    // 하단 그라데이션 + 닉네임 + 좋아요
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black54, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              post.nickname,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.favorite,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  "0",  // 좋아요 기능은 나중에 구현
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
    ],
  );
}

  // 💬 플로팅 버튼 위 말풍선
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
          bottom: -12,
          child: CustomPaint(
            size: const Size(20, 12),
            painter: _BubbleTailPainter(),
          ),
        ),
      ],
    );
  }
}

// 🎨 플로팅 버튼 위 말풍선 꼬리
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

// 🎨 타이머 아래 말풍선 꼬리
class _BubbleUpTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0) // 위 중앙 뾰족
      ..lineTo(0, size.height) // 왼쪽 아래
      ..lineTo(size.width, size.height) // 오른쪽 아래
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
