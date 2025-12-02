import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart'; // ✅ 메인 페이지 import
import 'package:flutter/cupertino.dart'; // 추가
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // Import dart:convert for JSON encoding/decoding


class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
bool _isIdChecked = false;
bool _isIdAvailable = false;

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

Future<bool?> _checkIdDuplicated(String id) async {
  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/check-id-duplication'), // Your backend URL for Android emulator
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'id': id,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData['isDuplicated'];
    } else {
      // Handle non-200 status codes as server errors
      _showAlertDialog('오류', '서버 오류가 발생했습니다 (${response.statusCode}). 다시 시도해주세요.');
      print('Failed to check ID duplication: ${response.statusCode}');
      return null; // Indicate an error occurred
    }
  } catch (e) {
    // Handle network errors
    _showAlertDialog('오류', '네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요.');
    print('Error checking ID duplication: $e');
    return null; // Indicate an error occurred
  }
}

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  bool _isValidId = false;
  bool _showIdError = false;
  bool _isValidNickname = false;
  bool _showNicknameError = false;

  // ✅ 정규식 규칙
  final RegExp _idRegExp = RegExp(r'^(?=.*[a-z])(?=.*\d)[a-z0-9]{4,20}$');
  final RegExp _nicknameRegExp = RegExp(r'^[a-zA-Z가-힣]{1,10}$');

  void _validateId() {
  final text = _idController.text.trim();
  final isValid = _idRegExp.hasMatch(text);
  setState(() {
    _isValidId = isValid;
    _showIdError = text.isNotEmpty && !isValid;

    // ✅ 아이디를 수정하는 순간, 이전 중복확인 결과는 무효화
    _isIdChecked = false;
    _isIdAvailable = false;
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

void _showDuplicateDialog(BuildContext context) {
  showCupertinoDialog(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: const Text('사용 중인 아이디입니다.'),
      content: const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          '이미 사용 중인 아이디입니다.\n다른 아이디를 입력해 주세요.',
        ),
      ),
      actions: [
        CupertinoDialogAction(
  isDestructiveAction: true, // 🔥 빨간색 버튼!
  onPressed: () => Navigator.of(context).pop(),
  child: const Text('확인'),
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
  onPressed: () => Navigator.of(context).pop(),
  child: const Text('확인'),
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
    final bool canSubmit =
    _isValidId && _isValidNickname && _isIdChecked && _isIdAvailable;


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
                      // ✅ X 아이콘 추가
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
                      onPressed: _isValidId
                      ? () async {
                        final id = _idController.text.trim();
                        if (id.isEmpty) return;
                        final bool? isDuplicated = await _checkIdDuplicated(id); // Use nullable bool
                        
                        if (isDuplicated == null) {
                          // An error occurred and _showAlertDialog was already called by _checkIdDuplicated
                          // No further action needed here for showing dialogs, but reset check status
                           setState(() {
                            _isIdChecked = false;
                            _isIdAvailable = false;
                          });
                          return;
                        }

                        setState(() {
                          _isIdChecked = true;          // 중복확인 버튼 눌렀다 표시
                          _isIdAvailable = !isDuplicated; // 사용 가능 여부 저장
                        });
                        if (isDuplicated) {
                          _showDuplicateDialog(context);   // ❌ 사용 중인 아이디 팝업
                        } else {
                          _showAvailableDialog(context);   // ✅ 사용 가능한 아이디 팝업
                        }
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
             // inputFormatters: [
             //   FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z가-힣]')),
             // ],
              decoration: InputDecoration(
                hintText: '닉네임',
                hintStyle: const TextStyle(color: Colors.black38),
                filled: true,
                fillColor: const Color(0xFFF3F3F3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                // ✅ 닉네임에도 X 아이콘 추가
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
              style: TextStyle(
                color: _showNicknameError ? Colors.red : Colors.black45,
                fontSize: 12,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 50),

            // 🔹 가입 완료 버튼
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
                                const LookupHomePage(), // ✅ 메인 페이지로 이동
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
