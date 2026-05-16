import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/features/auth/application/auth_provider.dart';
import 'feed_state.dart';

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final authState = ref.watch(authProvider);
  return FeedNotifier(authState.user?.id);
});

class FeedNotifier extends StateNotifier<FeedState> {
  final String? _currentUserId;

  FeedNotifier(this._currentUserId) : super(const FeedState()) {
    fetchFeed();
  }

  Future<void> fetchFeed() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await ApiService.getFeed(_currentUserId);
      final posts = data.map<Post>((json) {
        return Post(
          id: json['id'] ?? '',
          authorId: json['authorId'] ?? '',
          authorName: json['author'] ?? 'Unknown',
          content: json['content'] ?? '',
          mediaUrl: json['mediaUrl'],
          location: json['location'],
          likeCount: json['likeCount'] ?? 0,
          commentCount: json['commentCount'] ?? 0,
          shareCount: json['shareCount'] ?? 0,
          isLiked: json['isLiked'] ?? false,
          isSaved: json['isSaved'] ?? false,
        );
      }).toList();
      state = state.copyWith(posts: posts, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> toggleLike(String postId) async {
    if (_currentUserId == null) return;
    try {
      // Optimistic UI update
      final previousPosts = state.posts;
      final updatedPosts = state.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(
            isLiked: !post.isLiked,
            likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
          );
        }
        return post;
      }).toList();
      state = state.copyWith(posts: updatedPosts);

      final success = await ApiService.likePost(_currentUserId!, postId);
      if (!success) {
        // Revert on failure
        state = state.copyWith(posts: previousPosts);
      }
    } catch (e) {
      // Handle error implicitly
    }
  }

  Future<void> deletePost(String postId) async {
    if (_currentUserId == null) return;
    try {
      final success = await ApiService.deletePost(postId, _currentUserId!);
      if (success) {
        final updatedPosts = state.posts.where((p) => p.id != postId).toList();
        state = state.copyWith(posts: updatedPosts);
      }
    } catch (e) {
      // Handle error implicitly
    }
  }
}
