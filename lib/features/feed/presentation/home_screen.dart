import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:model2/features/feed/application/feed_provider.dart';
import 'package:model2/features/auth/application/auth_provider.dart';
import 'post_card_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Delay to allow providers to mount
    Future.microtask(() => ref.read(feedProvider.notifier).fetchFeed());
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TruthNet.'),
        actions: [
          IconButton(
            icon: Icon(
              authState.user == null ? Icons.login_rounded : Icons.logout_rounded,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pushReplacementNamed(context, '/');
            },
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48), // Fitts' Law
          ),
        ],
      ),
      body: feedState.isLoading && feedState.posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(feedProvider.notifier).fetchFeed(),
              color: theme.colorScheme.primary,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: feedState.posts.length,
                itemBuilder: (context, index) {
                  final post = feedState.posts[index];
                  // Using Key for identity tracking
                  return PostCardWidget(key: ValueKey(post.id), post: post);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Post Feature
          Navigator.pushNamed(context, '/post');
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
