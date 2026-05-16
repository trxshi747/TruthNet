import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_state.freezed.dart';
part 'feed_state.g.dart';

@freezed
class Post with _$Post {
  const factory Post({
    required String id,
    required String authorId,
    required String authorName,
    required String content,
    String? mediaUrl,
    String? location,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(0) int shareCount,
    @Default(false) bool isLiked,
    @Default(false) bool isSaved,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

@freezed
class FeedState with _$FeedState {
  const factory FeedState({
    @Default([]) List<Post> posts,
    @Default(true) bool isLoading,
    String? errorMessage,
  }) = _FeedState;
}
