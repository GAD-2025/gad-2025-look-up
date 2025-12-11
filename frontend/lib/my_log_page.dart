import 'package:flutter/material.dart';

class MyLogPage extends StatelessWidget {
  const MyLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // zZ 아이콘 이미지
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Image.asset(
              "assets/icons/sleep_icon.png",
              width: 90, // ← 너가 원하는 크기로 조절하면 됨
              height: 90,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 2),

          // 닉네임
          const Text(
            "루거비 님",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 4),

          // 아이디
          const Text(
            "@lookup_user",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),

          const SizedBox(height: 30),

          // 상단 탭 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.grid_view_rounded,
                    size: 26,
                    color: Colors.black,
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 40,
                    height: 2,
                    color: Colors.black,
                  ),
                ],
              ),
              const SizedBox(width: 60),
              const Icon(Icons.map_outlined, size: 26, color: Colors.grey),
            ],
          ),

          const SizedBox(height: 90),

          // 안내 문구
          const Text(
            "아직 게시물을 올리지 않으셨군요",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "피드에 참여하여 내가 찍은 풍경을 자랑해볼까요?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),

          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
