import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart'; // ✅ 메인 페이지 import 추가

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  bool _isValidId = false;
  bool _showIdError = false;
  bool _isValidNickname = false;
  bool _showNicknameError = false;

  // ✅ 아이디: 영문 소문자 + 숫자 조합 4~20자
  final RegExp _idRegExp = RegExp(r'^(?=.*[a-z])(?=.*\d)[a-z0-9]{4,20}$');
  // ✅ 닉네임: 한글 또는 영문 10자 이내
  final RegExp _nicknameRegExp = RegExp(r'^[a-zA-Z가-힣]{1,10}$');

  void _validateId() {
    final text = _idController.text.trim();
    final isValid = _idRegExp.hasMatch(text);
    setState(() {
      _isValidId = isValid;
      _showIdError = text.isNotEmpty && !isValid;
    });
  }

  void _validateNickname() {
    final text = _nicknameController.text.trim();
    final isValid = _nicknameRegExp.hasMatch(text);
    setState(() {
      _isValidNickname = isValid;
      _showNicknameError = text.isNotEmpty && !isValid;
    });
  }

  @override
  void initState() {
    super.initState();
    _idController.addListener(_validateId);
    _nicknameController.addListener(_validateNickname);
  }

  @override
  void dispose() {
    _idController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = _isValidId && _isValidNickname;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '회원가입',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 아이디 입력
            const Text(
              '아이디',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _idController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9]')),
                    ],
                    decoration: InputDecoration(
                      hintText: '아이디',
                      hintStyle: const TextStyle(color: Colors.black38),
                      filled: true,
                      fillColor: const Color(0xFFF3F3F3),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _showIdError ? Colors.red : Colors.transparent,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _showIdError ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isValidId
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('중복확인 요청'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isValidId
                            ? Colors.black
                            : const Color(0xFFF3F3F3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '중복확인',
                        style: TextStyle(
                          color: _isValidId ? Colors.white : Colors.black45,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _showIdError
                  ? '영문 소문자와 숫자를 모두 포함한 4~20자의 아이디를 입력해주세요.'
                  : '영문 소문자 및 숫자 조합 4자 이상 20자 이내',
              style: TextStyle(
                color: _showIdError ? Colors.red : Colors.black45,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 닉네임 입력
            const Text(
              '닉네임',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nicknameController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z가-힣]')),
              ],
              decoration: InputDecoration(
                hintText: '닉네임',
                hintStyle: const TextStyle(color: Colors.black38),
                filled: true,
                fillColor: const Color(0xFFF3F3F3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _showNicknameError ? Colors.red : Colors.transparent,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _showNicknameError ? Colors.red : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _showNicknameError
                  ? '한글 또는 영문 10자 이내의 닉네임을 입력해주세요.'
                  : '한글 또는 영문 10자 이내\n닉네임은 설정에서 변경할 수 있어요.',
              style: TextStyle(
                color: _showNicknameError ? Colors.red : Colors.black45,
                fontSize: 12,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 50),

            // 🔹 가입 완료 버튼 → 메인 피드(LOoK UP 화면)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: canSubmit
                    ? () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const LookupHomePage(), // ✅ main.dart의 홈화면 실행
                          ),
                          (route) => false, // 뒤로가기 불가
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSubmit
                      ? Colors.black
                      : const Color(0xFFF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '가입 완료',
                  style: TextStyle(
                    color: canSubmit ? Colors.white : Colors.black45,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
