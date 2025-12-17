import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'main.dart'; // ✅ 메인 페이지 import
import 'config.dart'; // Import the config file

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // ===== 상태 변수들 =====
  bool _isValidId = false; // 아이디 정규식 통과 여부
  bool _isIdChecked = false; // 아이디 중복확인 완료 여부
  bool _isIdAvailable = false; // 사용 가능한 아이디인지 여부
  bool _showIdError = false;

  bool _isValidNickname = false;
  bool _showNicknameError = false;

  String _lastCheckedId = '';

  // ✅ 중복확인 버튼 활성 여부
  bool get _canPressCheckButton => _isValidId && !_isIdChecked;

  // 컨트롤러
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  // 정규식
  final RegExp _idRegExp = RegExp(r'^(?=.*[a-z])(?=.*\d)[a-z0-9]{4,20}$');
  final RegExp _nicknameRegExp = RegExp(r'^[a-zA-Z가-힣]{1,10}$');

  // ===== 공통 알럿 =====
  void _showAlertDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ===== 아이디 중복 확인 API =====
  Future<bool?> _checkIdDuplicated(String id) async {
    try {
      final String baseUrl = getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/check-id-duplication'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'id': id}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['isDuplicated'] as bool;
      } else {
        _showAlertDialog(
          '오류',
          '서버 오류가 발생했습니다 (${response.statusCode}). 다시 시도해주세요.',
        );
        print('Failed to check ID duplication: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _showAlertDialog('오류', '네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요.');
      print('Error checking ID duplication: $e');
      return null;
    }
  }

  // ===== 입력 검증 =====
  void _validateId() {
    final text = _idController.text.trim();
    final isValid = _idRegExp.hasMatch(text);

    setState(() {
      _isValidId = isValid;
      _showIdError = text.isNotEmpty && !isValid;

      // ✅ 아이디를 “실제로” 바꿨을 때만 중복확인 결과를 무효화
      if (text != _lastCheckedId) {
        _isIdChecked = false;
        _isIdAvailable = false;
      }
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

  // ===== 다이얼로그들 =====
  void _showDuplicateDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('사용 중인 아이디입니다.'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text('이미 사용 중인 아이디입니다.\n다른 아이디를 입력해 주세요.'),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('확인'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showAvailableDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('사용 가능한 아이디입니다.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('확인'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // ===== 라이프사이클 =====
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

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final bool canSubmit = _isValidId && _isValidNickname && _isIdAvailable;

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
            // ===== 아이디 =====
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
                      suffixIcon: _idController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.cancel_rounded,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _idController.clear();
                                  _isValidId = false;
                                  _showIdError = false;
                                  _isIdChecked = false;
                                  _isIdAvailable = false;
                                });
                              },
                            )
                          : null,
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
                      onPressed: _canPressCheckButton
                          ? () async {
                              final id = _idController.text.trim();
                              if (id.isEmpty) return;

                              final bool? isDuplicated =
                                  await _checkIdDuplicated(id);

                              if (isDuplicated == null) {
                                // 서버/네트워크 에러
                                setState(() {
                                  _isIdChecked = false;
                                  _isIdAvailable = false;
                                  _lastCheckedId = ''; // ❗ 실패했으니 체크된 아이디 초기화
                                });
                                return;
                              }

                              if (isDuplicated) {
                                // ❌ 중복 아이디
                                setState(() {
                                  _isIdChecked = true; // "검사는 했다"
                                  _isIdAvailable = false; // 사용 불가
                                  _lastCheckedId = id; // 이 아이디로 검사했다는 흔적 남김
                                });

                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  _showDuplicateDialog(context);
                                });
                              } else {
                                // ✅ 사용 가능한 아이디
                                setState(() {
                                  _isIdChecked = true; // "검사는 했다"
                                  _isIdAvailable = true; // 사용 가능
                                  _lastCheckedId = id; // 이 아이디가 OK라고 확인됨
                                });

                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  _showAvailableDialog(context);
                                });
                              }

                              print(
                                '✅ 상태: '
                                '_isValidId=$_isValidId, '
                                '_isIdChecked=$_isIdChecked, '
                                '_isIdAvailable=$_isIdAvailable, '
                                '_canPressCheckButton=$_canPressCheckButton',
                              );
                            }
                          : null,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canPressCheckButton
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
                          color: _canPressCheckButton
                              ? Colors.white
                              : Colors.black45,
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

            // ===== 닉네임 =====
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
              decoration: InputDecoration(
                hintText: '닉네임',
                hintStyle: const TextStyle(color: Colors.black38),
                filled: true,
                fillColor: const Color(0xFFF3F3F3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: _nicknameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.cancel_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _nicknameController.clear();
                            _isValidNickname = false;
                            _showNicknameError = false;
                          });
                        },
                      )
                    : null,
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
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 12,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 50),

            // ===== 가입 완료 버튼 =====
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
                                const LookupMain(), // 메인 페이지로 이동
                          ),
                          (route) => false,
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
