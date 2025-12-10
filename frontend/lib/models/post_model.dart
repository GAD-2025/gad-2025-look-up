// lib/models/post_model.dart

class PostModel {
  final String imagePath;   // 이미지 또는 동영상 파일 경로
  final String caption;     // 캡션 내용
  final bool isVideo;       // 사진인지, 영상인지
  final bool isSender;      // 알림 보낸 사람인지 여부
  final String nickname;    // 작성자 닉네임
  final DateTime createdAt; // 작성 시간

  PostModel({
    required this.imagePath,
    required this.caption,
    required this.isVideo,
    required this.isSender,
    required this.nickname,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
