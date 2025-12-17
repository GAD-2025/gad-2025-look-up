import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../pages/preview_page.dart';
import '../models/post_model.dart';

enum CameraMode { photo, video }

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  // ---------------------------
  // 1) 상태 변수
  // ---------------------------
  CameraController? _controller;
  bool _isInitialized = false;

  bool _showGuideMessage = true;

  CameraMode _mode = CameraMode.photo;
  bool _isRecording = false;
  int _recordSeconds = 0;

  double _zoomLevel = 1.0;
  FlashMode _flashMode = FlashMode.off;

  // ---------------------------
  // PreviewPage 열고 PostModel 반환받기
  // ---------------------------
  Future<void> _openPreview(File file, {required bool isVideo}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewPage(
          filePath: file.path,
          isVideo: isVideo,
        ),
      ),
    );

    if (!mounted) return;

    // PreviewPage에서 PostModel을 반환하면 CameraPage 종료하며 전달
    if (result != null && result is PostModel) {
      Navigator.pop(context, result);
    }
  }

  @override
  void initState() {
    super.initState();
    _initCamera();

    // 안내문구 2초 후 사라짐
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showGuideMessage = false;
        });
      }
    });
  }

  // ---------------------------
  // 카메라 초기화
  // ---------------------------
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final rearCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
    );

    _controller = CameraController(
      rearCamera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    await _controller!.initialize();
    setState(() => _isInitialized = true);
  }

  // ---------------------------
  // 플래시 토글
  // ---------------------------
  Future<void> _toggleFlash() async {
    if (_flashMode == FlashMode.off) {
      await _controller?.setFlashMode(FlashMode.torch);
      setState(() => _flashMode = FlashMode.torch);
    } else {
      await _controller?.setFlashMode(FlashMode.off);
      setState(() => _flashMode = FlashMode.off);
    }
  }

  // ---------------------------
  // 줌
  // ---------------------------
  Future<void> _setZoom(double value) async {
    await _controller?.setZoomLevel(value);
    setState(() => _zoomLevel = value);
  }

  // ---------------------------
  // 사진 촬영
  // ---------------------------
  Future<void> _takePhoto() async {
    if (!_controller!.value.isInitialized) return;

    final XFile xfile = await _controller!.takePicture();
    final file = File(xfile.path);

    await _openPreview(file, isVideo: false);
  }

  // ---------------------------
  // 동영상 녹화 시작
  // ---------------------------
  Future<void> _startVideoRecording() async {
    if (!_controller!.value.isInitialized) return;

    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });

    await _controller!.startVideoRecording();

    // 5초 녹화 타이머
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording) break;

      setState(() => _recordSeconds++);
    }

    if (_isRecording && _recordSeconds >= 5) {
      await _stopVideoRecording();
    }
  }

  // ---------------------------
  // 녹화 종료
  // ---------------------------
  Future<void> _stopVideoRecording() async {
    if (!_controller!.value.isRecordingVideo) return;

    final XFile videoFile = await _controller!.stopVideoRecording();
    setState(() => _isRecording = false);

    final File file = File(videoFile.path);
    await _openPreview(file, isVideo: true);
  }

  // ---------------------------
  // dispose
  // ---------------------------
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ---------------------------
  // 안내 메시지
  // ---------------------------
  Widget _buildGuideMessage() {
    return AnimatedOpacity(
      opacity: _showGuideMessage ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            "풍경만 담아주세요",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------
  // 줌 버튼
  // ---------------------------
  Widget _buildZoomButton(double value) {
    return GestureDetector(
      onTap: () => _setZoom(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _zoomLevel == value ? Colors.white : Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
        ),
        child: Text(
          "${value}x",
          style: TextStyle(
            color: _zoomLevel == value ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ---------------------------
  // build()
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isInitialized
            ? Stack(
                children: [
                  // 카메라 프리뷰
                  Center(child: CameraPreview(_controller!)),

                  // ← 뒤로가기
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // 플래시 버튼
                  Positioned(
                    top: 16,
                    right: 70,
                    child: IconButton(
                      icon: Icon(
                        _flashMode == FlashMode.off
                            ? Icons.flash_off
                            : Icons.flash_on,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        if (_mode == CameraMode.photo) _toggleFlash();
                      },
                    ),
                  ),

                  // 안내 메시지
                  if (_showGuideMessage) Positioned.fill(child: _buildGuideMessage()),

                  // 하단 UI
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 줌
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildZoomButton(0.5),
                            const SizedBox(width: 12),
                            _buildZoomButton(1.0),
                            const SizedBox(width: 12),
                            _buildZoomButton(2.0),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // 사진 / 동영상 전환
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _mode = CameraMode.photo),
                              child: Text(
                                "사진",
                                style: TextStyle(
                                  color: _mode == CameraMode.photo
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            GestureDetector(
                              onTap: () => setState(() => _mode = CameraMode.video),
                              child: Text(
                                "동영상",
                                style: TextStyle(
                                  color: _mode == CameraMode.video
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // 촬영 버튼
                        GestureDetector(
                          onTap: () async {
                            if (_mode == CameraMode.photo) {
                              await _takePhoto();
                            } else {
                              if (!_isRecording) {
                                await _startVideoRecording();
                              } else {
                                await _stopVideoRecording();
                              }
                            }
                          },
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _mode == CameraMode.photo
                                    ? Colors.white
                                    : Colors.red,
                                width: 4,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _mode == CameraMode.photo
                                      ? Colors.white
                                      : (_isRecording
                                          ? Colors.red
                                          : Colors.red.shade400),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
      ),
    );
  }
}
