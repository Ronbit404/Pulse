import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../actions.dart';
import '../app_dependencies.dart';
import '../controllers/feed_controller.dart';
import '../models/user.dart';
import '../routes.dart';
import '../theme.dart';
import '../widgets/message_view.dart';
import '../widgets/post_card.dart';
import '../widgets/user_avatar.dart';

/// A user's profile. Used as the Profile tab (the signed-in account) and as the
/// `/profile` route for anyone else.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.deps, required this.userId});

  final AppDependencies deps;
  final int userId;

  bool get _isMe => userId == FeedController.currentUserId;

  @override
  Widget build(BuildContext context) {
    final feed = deps.feed;
    return ListenableBuilder(
      listenable: Listenable.merge([
        feed,
        deps.likes.listenable(),
        deps.favorites.listenable(),
      ]),
      builder: (context, _) {
        final user = feed.userFor(userId);
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: feed.isLoading
                ? const Center(child: CircularProgressIndicator())
                : MessageView(
                    icon: Icons.person_off_outlined,
                    message: feed.error ?? 'This profile could not be found.',
                    actionLabel: 'Retry',
                    onAction: feed.load,
                  ),
          );
        }

        final posts = feed.postsBy(userId);
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(_isMe ? 'Profile' : user.name)),
          body: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: [
              _Header(deps: deps, user: user, isMe: _isMe),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Stat(label: 'Posts', value: posts.length),
                  if (_isMe) ...[
                    _Stat(label: 'Liked', value: deps.likes.count),
                    _Stat(
                      label: 'Saved',
                      value: deps.favorites.count,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.favorites),
                    ),
                  ],
                ],
              ),
              const Divider(height: AppSpacing.lg * 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('Posts', style: theme.textTheme.titleMedium),
              ),
              if (posts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: Text('No posts yet.')),
                )
              else
                for (final post in posts)
                  PostCard(key: ValueKey(post.id), deps: deps, post: post),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.deps, required this.user, required this.isMe});

  final AppDependencies deps;
  final User user;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          UserAvatar(name: user.name, radius: 44),
          const SizedBox(height: AppSpacing.md),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          Text(
            '@${user.username}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            user.catchPhrase,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              _InfoChip(icon: Icons.place_outlined, label: user.city),
              _InfoChip(icon: Icons.business_outlined, label: user.companyName),
              _InfoChip(icon: Icons.link, label: user.website),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (isMe)
            const Chip(
              avatar: Icon(Icons.verified_user_outlined, size: 18),
              label: Text('This is your account'),
            )
          else
            ValueListenableBuilder<Box<bool>>(
              valueListenable: deps.following.listenable(keys: [user.id]),
              builder: (context, _, __) {
                final following = deps.following.contains(user.id);
                return following
                    ? OutlinedButton.icon(
                        onPressed: () => toggleFollow(context, deps, user.id),
                        icon: const Icon(Icons.check),
                        label: const Text('Following'),
                      )
                    : FilledButton.icon(
                        onPressed: () => toggleFollow(context, deps, user.id),
                        icon: const Icon(Icons.person_add_alt),
                        label: const Text('Follow'),
                      );
              },
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.onTap});

  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          children: [
            Text('$value', style: theme.textTheme.headlineSmall),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
