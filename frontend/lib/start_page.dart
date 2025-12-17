import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'signup_page.dart';
import 'main.dart';
import 'user_session.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  static const String _serverBaseUrl = 'http://10.0.2.2:3000';
  bool _isLoading = false;

  // 카카오 SDK로 로그인 시도
  Future<kakao.User?> _loginWithKakao() async {
    try {
      bool isInstalled = await kakao.isKakaoTalkInstalled();
      if (isInstalled) {
        await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }
      return await kakao.UserApi.instance.me();
    } catch (error) {
      print("카카오 로그인 실패: $error");
      return null;
    }
  }

  // 백엔드에 인증 요청
  Future<void> _authenticateWithBackend(String kakaoId) async {
    try {
      final response = await http.post(
        Uri.parse('$_serverBaseUrl/auth/kakao'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'kakaoId': kakaoId}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['isRegistered']) {
          // 이미 가입된 사용자 -> 로그인 처리
          final user = AppUser.fromJson(responseData['user']);
          await UserSession.saveUser(user);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LookupMain()),
            (route) => false,
          );
        } else {
          // 미가입 사용자 -> 회원가입 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SignupPage(kakaoId: kakaoId)),
          );
        }
      } else {
        _showErrorDialog('서버와 통신 중 오류가 발생했습니다.');
      }
    } catch (e) {
      _showErrorDialog('네트워크 오류가 발생했습니다.');
    }
  }

  // 카카오 로그인 버튼 핸들러
  Future<void> _handleKakaoLogin() async {
    setState(() => _isLoading = true);
    try {
      final kakaoUser = await _loginWithKakao();
      if (kakaoUser != null) {
        await _authenticateWithBackend(kakaoUser.id.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('확인'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Center(child: Image.asset('assets/logo.png', height: 50)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFFEE500),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onPressed: _isLoading ? null : _handleKakaoLogin,
                      child: _isLoading
                          ? const CupertinoActivityIndicator()
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Image.asset('assets/icons/kakao_icon.png', width: 20, height: 20),
                                ),
                                const Text(
                                  '카카오톡으로 시작하기',
                                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                    ),
                  ),

                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
