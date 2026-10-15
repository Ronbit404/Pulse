import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../actions.dart';
import '../app_dependencies.dart';
import '../controllers/feed_controller.dart';
import '../models/post.dart';
import '../routes.dart';
import '../theme.dart';
import 'post_image.dart';
import 'user_avatar.dart';

/// A post in the feed. With [detailed] the full text is shown and tapping the
/// card does nothing (used on the post details screen).
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.deps,
    required this.post,
    this.detailed = false,
  });

  final AppDependencies deps;
  final Post post;
  final bool detailed;

  bool get _isMine =>
      post.isLocal && post.userId == FeedController.currentUserId;

  Future<void> _confirmDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text(
          'This removes the post from your device, along with any likes and '
          'saves on it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await deps.feed.deleteOwnPost(post);
      messenger.showSnackBar(const SnackBar(content: Text('Post deleted.')));
    } on HiveError catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete the post: ${e.message}')),
      );
    }
  }

  void _openDetails(BuildContext context) =>
      Navigator.pushNamed(context, AppRoutes.details, arguments: post.toMap());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = deps.feed.userFor(post.userId);
    final name = author?.name ?? 'User ${post.userId}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: cardShape(context),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: detailed ? null : () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.profile,
                      arguments: post.userId,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UserAvatar(name: name, radius: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: theme.textTheme.titleMedium),
                            if (author != null)
                              Text(
                                '@${author.username}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (_isMine && !detailed)
                    PopupMenuButton<String>(
                      tooltip: 'More',
                      onSelected: (_) => _confirmDelete(context),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'delete', child: Text('Delete post')),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                post.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                post.body,
                maxLines: detailed ? null : 4,
                overflow: detailed ? TextOverflow.visible : TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
              if (post.hasImage)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: PostImage(url: post.imageUrl),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  ValueListenableBuilder<Box<bool>>(
                    valueListenable: deps.likes.listenable(keys: [post.id]),
                    builder: (context, _, __) {
                      final liked = deps.likes.contains(post.id);
                      return TextButton.icon(
                        onPressed: () => toggleLike(context, deps, post),
                        icon: Icon(
                          liked ? Icons.favorite : Icons.favorite_border,
                          color: liked ? Colors.redAccent : null,
                        ),
                        label: Text(liked ? 'Liked' : 'Like'),
                      );
                    },
                  ),
                  ListenableBuilder(
                    listenable: deps.feed,
                    builder: (context, _) => TextButton.icon(
                      onPressed: detailed ? null : () => _openDetails(context),
                      icon: const Icon(Icons.mode_comment_outlined),
                      label: Text('${deps.feed.commentCountFor(post.id)}'),
                    ),
                  ),
                  const Spacer(),
                  ValueListenableBuilder<Box<Map>>(
                    valueListenable: deps.favorites.listenable(keys: [post.id]),
                    builder: (context, _, __) {
                      final saved = deps.favorites.contains(post.id);
                      return IconButton(
                        tooltip: saved ? 'Remove from saved' : 'Save post',
                        onPressed: () => toggleSaved(context, deps, post),
                        icon: Icon(
                          saved ? Icons.bookmark : Icons.bookmark_border,
                          color: saved ? theme.colorScheme.primary : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
