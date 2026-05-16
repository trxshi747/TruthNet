import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:model2/features/auth/application/auth_provider.dart';
import 'package:model2/core/widgets/user_avatar.dart';
import 'package:model2/core/widgets/minimal_divider.dart';
import 'package:model2/features/feed/application/feed_provider.dart';
import 'package:model2/features/feed/presentation/post_card_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please log in to view profile.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(user.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48), // Fitts' Law
          )
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        UserAvatar(
                          initial: user.firstName,
                          imageUrl: user.profileImageUrl,
                          radius: 40,
                        ),
                        const Spacer(),
                        _buildStatColumn('Posts', '12', theme),
                        const SizedBox(width: 24),
                        _buildStatColumn('Followers', '1.2k', theme),
                        const SizedBox(width: 24),
                        _buildStatColumn('Following', '430', theme),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (user.bio != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.bio!,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44), // Fitts' Law
                          side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Edit Profile', style: theme.textTheme.titleSmall),
                      ),
                    ),
                  ],
                ).animate().fade(duration: 400.ms).slideY(begin: 0.1),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: theme.colorScheme.onSurface,
                  labelColor: theme.colorScheme.onSurface,
                  unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
                  tabs: const [
                    Tab(text: 'Posts'),
                    Tab(text: 'Replies'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildUserPosts(ref),
            const Center(child: Text('No replies yet.')),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count, ThemeData theme) {
    return Column(
      children: [
        Text(count, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildUserPosts(WidgetRef ref) {
    final feedState = ref.watch(feedProvider);
    final authState = ref.watch(authProvider);

    final userPosts = feedState.posts.where((p) => p.authorId == authState.user?.id).toList();

    if (userPosts.isEmpty) {
      return const Center(child: Text('No posts yet.'));
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: userPosts.length,
      itemBuilder: (context, index) {
        return PostCardWidget(key: ValueKey(userPosts[index].id), post: userPosts[index]);
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
