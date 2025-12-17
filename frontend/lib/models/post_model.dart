// lib/models/post_model.dart

class PostModel {
  final String imagePath;   // 이미지 또는 동영상 파일 경로
  final String caption;     // 캡션 내용
  final bool isVideo;       // 사진인지, 영상인지
  final String userId;      // 작성자 ID
  final String nickname;    // 작성자 닉네임 (추가됨)
  final DateTime createdAt; // 작성 시간

  PostModel({
    required this.imagePath,
    required this.caption,
    required this.isVideo,
    required this.userId,
    required this.nickname, // 닉네임 필드를 필수 값으로 추가
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Method to convert PostModel to a JSON format
  Map<String, dynamic> toJson() {
    return {
      'imagePath': imagePath,
      'caption': caption,
      'isVideo': isVideo,
      'userId': userId,
      'nickname': nickname, // toJson에 닉네임 추가
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Factory constructor to create a PostModel from a JSON object
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      imagePath: json['image_path'],
      caption: json['caption'],
      isVideo: json['is_video'] == 1,
      userId: json['user_id'],
      nickname: json['nickname'], // fromJson에서 닉네임 파싱
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
