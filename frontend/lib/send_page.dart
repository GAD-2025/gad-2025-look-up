import 'package:flutter/material.dart';

class SendPage extends StatefulWidget {
  const SendPage({super.key});

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  final TextEditingController _emojiController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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

      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(top: 16.0, right: 20.0),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // 🟦 이모티콘 입력 박스
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _emojiController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 40),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '😀',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 32),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            '포착한 풍경을 이모지로 표현해 보세요',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '입력한 이모지가 피드명에 함께 표시됩니다',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 40),

          // ✅ 전송하기 버튼
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _emojiController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              '전송하기',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
