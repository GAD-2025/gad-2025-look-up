import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  // 🔥 로그인 결과를 true/false로 알려주는 함수
  Future<bool> loginWithKakao() async {
    try {
      bool isInstalled = await isKakaoTalkInstalled();

      if (isInstalled) {
        await UserApi.instance.loginWithKakaoTalk();
      } else {
        await UserApi.instance.loginWithKakaoAccount();
      }

      print("로그인 성공!");
      return true;  // 성공
    } catch (error) {
      print("카카오 로그인 실패: $error");
      return false; // 실패
    }
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

            // 🟨 카카오 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_rounded, color: Colors.black),

                  // ⭐ 여기가 핵심 수정
                  onPressed: () async {
                    final success = await loginWithKakao();

                    if (!success) return; // 실패하면 이동 X

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupPage(),
                      ),
                    );
                  },

                  label: const Text(
                    '카카오톡으로 시작하기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // 🟩 네이버 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03C75A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Text(
                    'N',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupPage(),
                      ),
                    );
                  },
                  label: const Text(
                    '네이버로 시작하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
