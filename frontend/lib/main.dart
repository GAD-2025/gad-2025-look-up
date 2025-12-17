import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Pages
import 'start_page.dart';
import 'send_page.dart';
import 'my_log_page.dart';
import 'pages/camera_page.dart';

// Models
import 'models/post_model.dart';
import 'user_session.dart'; // 사용자 세션

// --- Constants ---
const String _serverBaseUrl = 'http://10.0.2.2:3000';

void main() {
  // Kakao SDK 초기화
  KakaoSdk.init(nativeAppKey: '03033934ad0bba787529944420a0e059');
  runApp(const LookupApp());
}

class LookupApp extends StatelessWidget {
  const LookupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<AppUser?>(
        future: UserSession.getUser(), // 저장된 사용자 정보 가져오기
        builder: (context, snapshot) {
          // 로딩 중일 때
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CupertinoActivityIndicator()),
            );
          }

          // 사용자 정보가 있을 때 (자동 로그인 성공)
          if (snapshot.hasData && snapshot.data != null) {
            return const LookupMain();
          }
          
          // 사용자 정보가 없을 때
          return const StartPage();
        },
      ),
    );
  }
}

class LookupMain extends StatefulWidget {
  const LookupMain({super.key});

  @override
  State<LookupMain> createState() => _LookupMainState();
}

class _LookupMainState extends State<LookupMain> {
  int _selectedIndex = 0;

  String _currentLocation = "위치 불러오는 중...";
  String? _emoji;
  bool _hasFeed = false;
  int _remainingSeconds = 0;
  bool _showTimer = false;
  bool _isTimeout = false;
  bool _isButtonDisabled = false;
  List<PostModel> feedPosts = [];
  int? _feedId; // The ID of the currently active feed

  @override
  void initState() {
    super.initState();
    _loadLocation();
    // _fetchPosts(); // Removed: Posts will be fetched only for a specific feed.
  }

  // Fetch posts for a specific feed
  Future<void> _fetchPosts(int feedId) async {
    try {
      final url = Uri.parse('$_serverBaseUrl/api/feeds/$feedId/posts');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> postJson = json.decode(response.body);
        setState(() {
          feedPosts = postJson.map((json) => PostModel.fromJson(json)).toList();
        });
      } else {
        // Handle server error
        print('Failed to load posts for feed $feedId: ${response.body}');
      }
    } catch (e) {
      // Handle connection error
      print('Error fetching posts: $e');
    }
  }

  // Create a new feed on the backend
  Future<int?> _createFeed(String emoji) async {
    final url = Uri.parse('$_serverBaseUrl/api/feeds');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'emoji': emoji,
          'location': _currentLocation,
        }),
      );
      if (response.statusCode == 201) {
        final responseBody = json.decode(response.body);
        return responseBody['feedId'];
      } else {
        print('Failed to create feed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating feed: $e');
      return null;
    }
  }


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

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));

      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
        return true;
      }

      setState(() {
        _isTimeout = true;
        _showTimer = true; // Keep timer visible to show "TIME OUT"
      });

      return false;
    });
  }

  String _formatTime(int sec) =>
      "${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}";

  void _showToast() {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 120,
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

  Widget _buildTimerButton() {
    final bool isDisabled = _isTimeout || feedPosts.isNotEmpty;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () async {
              if (_feedId == null) return; // Should not happen if button is visible

              // Navigate to the camera, passing the feedId
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CameraPage(feedId: _feedId!)),
              );

              // When returning from the camera flow, refresh the feed.
              _fetchPosts(_feedId!);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isDisabled ? const Color(0xFFF1F1F1) : Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              color: isDisabled ? Colors.grey : Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              _isTimeout ? 'TIME OUT' : _formatTime(_remainingSeconds),
              style: TextStyle(
                color: isDisabled ? Colors.grey : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _hasFeed ? _buildFeedView() : _buildEmptyView(),
      const MyLogPage(),
    ];

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
      body: IndexedStack(index: _selectedIndex, children: pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_isButtonDisabled) return;

          final emoji = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SendPage()),
          );

          if (emoji == null || emoji is! String || emoji.isEmpty) return;

          // Create feed on the backend
          final newFeedId = await _createFeed(emoji);

          if (newFeedId != null) {
            setState(() {
              feedPosts.clear(); // Clear old posts before setting new feed
              _feedId = newFeedId; // Store the new feed ID
              _emoji = emoji;
              _hasFeed = true;
              _showTimer = true;
              _isTimeout = false;
              _remainingSeconds = 180;
              _isButtonDisabled = true;
            });

            _showToast();
            _startTimer();
          } else {
            // Show error to user if feed creation fails
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('피드를 생성하는데 실패했습니다. 다시 시도해주세요.')),
              );
            }
          }
        },
        backgroundColor: _isButtonDisabled ? Colors.grey : Colors.black,
        elevation: _isButtonDisabled ? 0 : 6,
        shape: const CircleBorder(),
        child: Image.asset('assets/lookup_icon.png', width: 35, height: 35),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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

  Widget _buildFeedView() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 16),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
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
        ),
        if (_showTimer)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTimerButton(),
                  const SizedBox(height: 20),
                  if (feedPosts.isEmpty) _buildTimerBubble(),
                ],
              ),
            ),
          ),
        if (feedPosts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 160),
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
                final imageUrl = '$_serverBaseUrl${post.imagePath}';

                return GestureDetector(
                  onTap: () {
                    print("게시물 클릭: ${post.userId}");
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          // Optional: Add loading and error builders for better UX
                          loadingBuilder: (context, child, progress) {
                            return progress == null
                                ? child
                                : const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.error_outline, color: Colors.grey[600]),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black54, Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  post.userId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Row(
                                children: [
                                  Icon(Icons.favorite, 
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    "0",
                                    style: TextStyle(
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

  Widget _buildTimerBubble() {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -10,
          child: CustomPaint(
            size: const Size(20, 10),
            painter: _BubbleUpTailPainter(),
          ),
        ),
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
    );
  }
}

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

class _BubbleUpTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}