import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:model2/features/feed/application/feed_provider.dart';
import 'package:model2/features/feed/application/feed_state.dart';
import 'package:model2/core/widgets/user_avatar.dart';
import 'package:model2/core/widgets/minimal_divider.dart';
import 'package:model2/services/api_service.dart';

class PostCardWidget extends ConsumerWidget {
  final Post post;

  const PostCardWidget({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                initial: post.authorName,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          post.authorName,
                          style: theme.textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          onPressed: () {},
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        ),
                      ],
                    ),
                    if (post.location != null)
                      Text(
                        post.location!,
                        style: theme.textTheme.bodySmall,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      post.content,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (post.mediaUrl != null)
          // Edge-to-edge media
          SizedBox(
            width: double.infinity,
            height: 300,
            child: Image.network(
              "${ApiService.baseUrl.replaceFirst('/api', '')}${post.mediaUrl}",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: theme.colorScheme.onSurface.withOpacity(0.05),
                child: Icon(Icons.broken_image_rounded, color: theme.colorScheme.onSurface.withOpacity(0.2)),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInteractionButton(
                context: context,
                icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                count: post.likeCount,
                color: post.isLiked ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.7),
                onTap: () => ref.read(feedProvider.notifier).toggleLike(post.id),
              ),
              _buildInteractionButton(
                context: context,
                icon: Icons.chat_bubble_outline_rounded,
                count: post.commentCount,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                onTap: () {},
              ),
              _buildInteractionButton(
                context: context,
                icon: Icons.repeat_rounded,
                count: post.shareCount,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                onTap: () {},
              ),
              _buildInteractionButton(
                context: context,
                icon: post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                count: 0,
                color: post.isSaved ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.7),
                onTap: () {},
              ),
            ],
          ),
        ),
        const MinimalDivider(),
      ],
    );
  }

  Widget _buildInteractionButton({
    required BuildContext context,
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48), // Fitts' Law Rule
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
