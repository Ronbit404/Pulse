import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../app_dependencies.dart';
import '../models/user.dart';
import '../routes.dart';
import '../theme.dart';
import '../widgets/message_view.dart';
import '../widgets/post_card.dart';
import '../widgets/user_avatar.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.deps});

  final AppDependencies deps;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = widget.deps;
    final feed = deps.feed;

    return Scaffold(
      appBar: AppBar(title: const Text('Pulse')),
      body: ListenableBuilder(
        listenable: feed,
        builder: (context, _) {
          if (feed.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (feed.error != null && !feed.hasServerData) {
            return MessageView(
              icon: Icons.cloud_off,
              message: feed.error!,
              actionLabel: 'Retry',
              onAction: feed.load,
            );
          }

          final posts = feed.visiblePosts;
          return RefreshIndicator(
            onRefresh: feed.load,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (feed.error != null)
                  SliverToBoxAdapter(child: _ErrorBanner(message: feed.error!)),
                SliverToBoxAdapter(child: _StoriesRow(deps: deps)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: feed.setQuery,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search posts or people',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: feed.query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  feed.setQuery('');
                                },
                              ),
                      ),
                    ),
                  ),
                ),
                if (posts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: MessageView(
                      icon: Icons.search_off,
                      message: 'No posts match "${feed.query}".',
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) => PostCard(
                      key: ValueKey(posts[index].id),
                      deps: deps,
                      post: posts[index],
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 88)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// People as story-style avatars; a gradient ring marks the ones you follow.
class _StoriesRow extends StatelessWidget {
  const _StoriesRow({required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) {
    final users = deps.feed.users;
    if (users.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 108,
      child: ValueListenableBuilder<Box<bool>>(
        valueListenable: deps.following.listenable(),
        builder: (context, _, __) => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          itemCount: users.length,
          itemBuilder: (context, index) => _StoryItem(
            user: users[index],
            following: deps.following.contains(users[index].id),
          ),
        ),
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({required this.user, required this.following});

  final User user;
  final bool following;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.profile, arguments: user.id),
        child: SizedBox(
          width: 68,
          child: Column(
            children: [
              UserAvatar(name: user.name, radius: 28, ring: following),
              const SizedBox(height: 6),
              Text(
                user.name.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.errorContainer,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        'Could not refresh: $message',
        style: TextStyle(color: scheme.onErrorContainer),
      ),
    );
  }
}
