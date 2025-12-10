import 'dart:io';
import 'package:flutter/material.dart';
import '../models/post_model.dart';

class PreviewPage extends StatefulWidget {
  final String filePath;
  final bool isSender;
  final String currentUserNickname;
  final bool isVideo;   // ⭐ 꼭 있어야 함

  const PreviewPage({
    super.key,
    required this.filePath,
    required this.isSender,
    required this.currentUserNickname,
    required this.isVideo,   // ⭐ 꼭 있어야 함
  });

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("미리보기",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: Center(
              child: widget.isVideo
                  ? const Text("동영상 재생은 추후 구현 예정",
                      style: TextStyle(color: Colors.white))
                  : Image.file(
                      File(widget.filePath),
                      fit: BoxFit.contain,
                    ),
            ),
          ),

          // 캡션
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.black,
            child: TextField(
              controller: _captionController,
              maxLength: 100,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "캡션을 입력하세요 (최대 100자)",
                hintStyle: const TextStyle(color: Colors.white54),
                counterStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white54),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // 공유하기 버튼
          GestureDetector(
            onTap: () {
              final newPost = PostModel(
                imagePath: widget.filePath,
                caption: _captionController.text,
                isVideo: widget.isVideo,
                isSender: widget.isSender,
                nickname: widget.currentUserNickname,
              );

              Navigator.pop(context, newPost);  // ← Feed로 post 전달
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.white,
              child: const Center(
                child: Text(
                  "공유하기",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
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
