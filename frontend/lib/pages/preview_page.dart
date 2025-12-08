import 'dart:io';
import 'package:flutter/material.dart';

class PreviewPage extends StatelessWidget {
  final String filePath;
  final bool isVideo;

  const PreviewPage({
    Key? key,
    required this.filePath,
    required this.isVideo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: isVideo
            ? Text(
                "영상 미리보기 구현 예정\n$filePath",
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              )
            : Image.file(
                File(filePath),
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}
