import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PreviewPage extends StatefulWidget {
  final String filePath;
  final bool isVideo;

  const PreviewPage({
    super.key,
    required this.filePath,
    required this.isVideo,
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

    // TODO: Replace 'gad123' with the actual logged-in user's ID
    const userId = 'gad123';

    // NOTE: 10.0.2.2 is for Android emulator. Use localhost or your IP for other platforms.
    final url = Uri.parse('http://10.0.2.2:3000/api/posts');
    
    try {
      // Create a multipart request
      final request = http.MultipartRequest('POST', url);

      // Add the file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // This key must match the one in backend: upload.single('image')
          widget.filePath,
        ),
      );

      // Add other fields
      request.fields['userId'] = userId;
      request.fields['caption'] = _captionController.text;
      request.fields['isVideo'] = widget.isVideo.toString();

      // Send the request
      final streamedResponse = await request.send();
      
      // Get the response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시물이 성공적으로 업로드되었습니다!')),
        );
        // Pop twice to go back to the screen before the camera
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        }
      } else {
        // Try to parse the error message from the response body
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
        title: const Text(
          "미리보기",
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
          GestureDetector(
            onTap: _sendPost, // Call the send post function
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.white,
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 3,
                        ),
                      )
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
