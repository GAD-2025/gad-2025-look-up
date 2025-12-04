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
      return true; // 성공
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

            // 🟡 로고
            Center(child: Image.asset('assets/logo.png', height: 50)),

            const Spacer(),

            // 🔹 좌우 여백 추가된 버튼 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28), // ✅ 좌우 여백 추가
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🟨 카카오 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFFEE500),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onPressed: () async {
                        final success = await loginWithKakao();
                        if (!success) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupPage(),
                          ),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Image.asset(
                              'assets/icons/kakao_icon.png',
                              width: 20,
                              height: 20,
                            ),
                          ),
                          const Text(
                            '카카오톡으로 시작하기',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 🟩 네이버 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF03C75A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupPage(),
                          ),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Image.asset(
                              'assets/icons/naver_icon.png',
                              width: 15,
                              height: 15,
                            ),
                          ),
                          const Text(
                            '네이버로 시작하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
