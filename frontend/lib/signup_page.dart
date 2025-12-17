import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'main.dart'; // 메인 페이지
import 'user_session.dart'; // 사용자 세션

class SignupPage extends StatefulWidget {
  final String kakaoId; // 카카오 ID를 받기 위한 변수

  const SignupPage({super.key, required this.kakaoId});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // 서버 주소
  static const String _serverBaseUrl = 'http://10.0.2.2:3000';

  // ===== 상태 변수들 =====
  bool _isLoading = false; // 로딩 상태
  bool _isValidId = false;
  bool _isIdChecked = false;
  bool _isIdAvailable = false;
  bool _showIdError = false;
  bool _isValidNickname = false;
  bool _showNicknameError = false;
  String _lastCheckedId = '';

  bool get _canPressCheckButton => _isValidId && !_isIdChecked && !_isLoading;

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  final RegExp _idRegExp = RegExp(r'^(?=.*[a-z])(?=.*\d)[a-z0-9]{4,20}$');
  final RegExp _nicknameRegExp = RegExp(r'^[a-zA-Z가-힣]{1,10}$');

  void _showAlertDialog(String title, String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('확인'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _checkIdDuplicated(String id) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_serverBaseUrl/check-id-duplication'), // URL 수정
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'id': id}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['isDuplicated'] as bool;
      } else {
        _showAlertDialog('오류', '서버 오류가 발생했습니다 (${response.statusCode}).');
        return null;
      }
    } catch (e) {
      _showAlertDialog('오류', '네트워크 오류가 발생했습니다.');
      return null;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // +++++ 신규 회원가입 제출 함수 +++++
  Future<void> _submitSignup() async {
    if (!(_isValidId && _isValidNickname && _isIdAvailable)) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_serverBaseUrl/signup'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'id': _idController.text.trim(),
          'nickname': _nicknameController.text.trim(),
          'kakaoId': widget.kakaoId,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final user = AppUser.fromJson(responseData['user']);

        // 세션에 사용자 정보 저장
        await UserSession.saveUser(user);

        // 메인 페이지로 이동 (모든 이전 페이지 제거)
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LookupMain()),
            (route) => false,
          );
        }
      } else {
        final responseData = jsonDecode(response.body);
        _showAlertDialog('회원가입 실패', responseData['message'] ?? '알 수 없는 오류가 발생했습니다.');
      }
    } catch (e) {
      _showAlertDialog('오류', '회원가입 중 네트워크 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _validateId() {
    final text = _idController.text.trim();
    final isValid = _idRegExp.hasMatch(text);
    if (_isValidId == isValid && _showIdError == (text.isNotEmpty && !isValid)) return;
    setState(() {
      _isValidId = isValid;
      _showIdError = text.isNotEmpty && !isValid;
      if (text != _lastCheckedId) {
        _isIdChecked = false;
        _isIdAvailable = false;
      }
    });
  }

  void _validateNickname() {
    final text = _nicknameController.text.trim();
    final isValid = _nicknameRegExp.hasMatch(text);
    if (_isValidNickname == isValid && _showNicknameError == (text.isNotEmpty && !isValid)) return;
    setState(() {
      _isValidNickname = isValid;
      _showNicknameError = text.isNotEmpty && !isValid;
    });
  }

  void _showDuplicateDialog() {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('사용 중인 아이디입니다.'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text('다른 아이디를 입력해 주세요.'),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('확인'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showAvailableDialog() {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('사용 가능한 아이디입니다.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('확인'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
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
    final bool canSubmit = _isValidId && _isValidNickname && _isIdAvailable && !_isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('회원가입', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('아이디', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _idController,
                    enabled: !_isLoading,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9]'))],
                    decoration: InputDecoration(
                      hintText: '아이디',
                      hintStyle: const TextStyle(color: Colors.black38),
                      filled: true,
                      fillColor: const Color(0xFFF3F3F3),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixIcon: _idController.text.isNotEmpty && !_isLoading
                          ? IconButton(
                              icon: const Icon(Icons.cancel_rounded, color: Colors.grey, size: 20),
                              onPressed: () {
                                _idController.clear();
                              },
                            )
                          : null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _showIdError ? Colors.red : Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _showIdError ? Colors.red : Colors.black),
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
                              final isDuplicated = await _checkIdDuplicated(id);
                              if (isDuplicated == null) return;

                              setState(() {
                                _isIdChecked = true;
                                _isIdAvailable = !isDuplicated;
                                _lastCheckedId = id;
                              });

                              if (!isDuplicated) {
                                _showAvailableDialog();
                              } else {
                                _showDuplicateDialog();
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canPressCheckButton ? Colors.black : const Color(0xFFF3F3F3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('중복확인', style: TextStyle(color: _canPressCheckButton ? Colors.white : Colors.black45, fontSize: 14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _showIdError ? '영문 소문자와 숫자를 모두 포함한 4~20자의 아이디를 입력해주세요.' : '영문 소문자 및 숫자 조합 4자 이상 20자 이내',
              style: TextStyle(color: _showIdError ? Colors.red : Colors.black45, fontSize: 12),
            ),
            const SizedBox(height: 30),
            const Text('닉네임', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 8),
            TextField(
              controller: _nicknameController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: '닉네임',
                hintStyle: const TextStyle(color: Colors.black38),
                filled: true,
                fillColor: const Color(0xFFF3F3F3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: _nicknameController.text.isNotEmpty && !_isLoading
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded, color: Colors.grey, size: 20),
                        onPressed: () => _nicknameController.clear(),
                      )
                    : null,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _showNicknameError ? Colors.red : Colors.transparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _showNicknameError ? Colors.red : Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _showNicknameError ? '한글 또는 영문 10자 이내의 닉네임을 입력해주세요.' : '한글 또는 영문 10자 이내\n닉네임은 설정에서 변경할 수 있어요.',
              style: const TextStyle(color: Colors.black45, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: canSubmit ? _submitSignup : null, // +++++ 수정된 부분 +++++
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSubmit ? Colors.black : const Color(0xFFF3F3F3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : Text(
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
