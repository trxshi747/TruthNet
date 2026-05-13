class Post {
  final String id;
  final String author;
  final String authorId;
  final String content;
  final String? mediaUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String visibility; // 'public' or 'private'
  final bool isEdited;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isSaved;

  Post({
    required this.id,
    required this.author,
    required this.authorId,
    required this.content,
    this.mediaUrl,
    required this.createdAt,
    this.updatedAt,
    this.visibility = 'public',
    this.isEdited = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isSaved = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      author: json['author'] ?? 'Anonymous',
      authorId: json['authorId'] ?? '',
      content: json['content'] ?? '',
      mediaUrl: json['mediaUrl'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt']) 
          : null,
      visibility: json['visibility'] ?? 'public',
      isEdited: json['isEdited'] ?? false,
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
    );
  }
}
