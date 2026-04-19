class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileUrl;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final int likeCount;
  final int commentCount;
  final bool isPublic;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileUrl,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isPublic = true,
  });
}
