import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../user_session.dart'; // 사용자 세션

class PreviewPage extends StatefulWidget {
  final String filePath;
  final bool isVideo;
  final int feedId; // To associate the post with a feed

  const PreviewPage({
    super.key,
    required this.filePath,
    required this.isVideo,
    required this.feedId,
  });

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  final TextEditingController _captionController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendPost() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // --- 로그인된 사용자 정보 가져오기 ---
    final AppUser? currentUser = await UserSession.getUser();

    if (currentUser == null) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오류: 로그인 정보가 없습니다. 다시 로그인해주세요.')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }
    // ---------------------------------

    final url = Uri.parse('http://10.0.2.2:3000/api/posts');
    
    try {
      final request = http.MultipartRequest('POST', url);

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          widget.filePath,
        ),
      );

      // --- Add all required fields ---
      request.fields['userId'] = currentUser.id;
      request.fields['caption'] = _captionController.text;
      request.fields['isVideo'] = widget.isVideo.toString();
      request.fields['feedId'] = widget.feedId.toString(); // Include the feedId

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시물이 성공적으로 업로드되었습니다!')),
        );
        // Pop both PreviewPage and CameraPage on success
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      } else {
        String errorMessage = '오류가 발생했습니다.';
        try {
          final responseBody = json.decode(response.body);
          errorMessage = responseBody['message'] ?? '오류: ${response.body}';
        } catch (e) {
          errorMessage = '오류: ${response.body}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('전송 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
        title: const Text("미리보기", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: widget.isVideo
                  ? const Text("동영상 재생은 추후 구현 예정", style: TextStyle(color: Colors.white))
                  : Image.file(File(widget.filePath), fit: BoxFit.contain),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.black,
            child: TextField(
              controller: _captionController,
              maxLength: 100,
              enabled: !_isLoading,
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
          GestureDetector(
            onTap: _isLoading ? null : _sendPost,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.white,
              child: Center(
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: Colors.black)
                    : const Text(
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
