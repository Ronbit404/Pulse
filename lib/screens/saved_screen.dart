import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../app_dependencies.dart';
import '../models/post.dart';
import '../routes.dart';
import '../theme.dart';
import '../widgets/message_view.dart';
import '../widgets/note_dialog.dart';
import '../widgets/user_avatar.dart';

/// Saved posts, each with an editable personal note. Used as the Saved tab and
/// as the `/favorites` route.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key, required this.deps});

  final AppDependencies deps;

  Future<void> _editNote(BuildContext context, FavoritePost favorite) async {
    final messenger = ScaffoldMessenger.of(context);
    final note = await showDialog<String>(
      context: context,
      builder: (_) => NoteDialog(initialNote: favorite.note),
    );
    if (note == null) return;
    try {
      await deps.favorites.updateNote(favorite.post.id, note);
      messenger.showSnackBar(const SnackBar(content: Text('Note saved.')));
    } on HiveError catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save the note: ${e.message}')),
      );
    } on StateError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    FavoritePost favorite,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove from saved?'),
        content: Text('"${favorite.post.title}" and its note will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await deps.favorites.remove(favorite.post.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Removed from your saved posts.')),
      );
    } on HiveError catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not remove the post: ${e.message}')),
      );
    }
  }

  Widget _buildList(BuildContext context) {
    final List<FavoritePost> favorites;
    try {
      favorites = deps.favorites.all();
    } on FormatException catch (e) {
      return MessageView(
        icon: Icons.error_outline,
        message: 'Your saved posts could not be read: ${e.message}',
      );
    }
    if (favorites.isEmpty) {
      return const MessageView(
        icon: Icons.bookmark_border,
        message: 'Nothing saved yet. Tap the bookmark on a post to keep it here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return Dismissible(
          key: ValueKey(favorite.post.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          // Deletion happens here; the box listener removes the row once the
          // delete completes, so the swipe always springs back first.
          confirmDismiss: (_) async {
            await _confirmAndDelete(context, favorite);
            return false;
          },
          child: _SavedTile(
            deps: deps,
            favorite: favorite,
            onEdit: () => _editNote(context, favorite),
            onDelete: () => _confirmAndDelete(context, favorite),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: ListenableBuilder(
        listenable: Listenable.merge([deps.favorites.listenable(), deps.feed]),
        builder: (context, _) => _buildList(context),
      ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({
    required this.deps,
    required this.favorite,
    required this.onEdit,
    required this.onDelete,
  });

  final AppDependencies deps;
  final FavoritePost favorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = favorite.post;
    final author = deps.feed.userFor(post.userId);
    final name = author?.name ?? 'User ${post.userId}';
    final hasNote = favorite.note.isNotEmpty;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: cardShape(context),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.details,
          arguments: post.toMap(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(name: name, radius: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.labelLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note),
                    tooltip: 'Edit note',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove from saved',
                    onPressed: onDelete,
                  ),
                ],
              ),
              Text(
                post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm + 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasNote ? favorite.note : 'No note yet. Tap the pencil to add one.',
                  style: hasNote
                      ? theme.textTheme.bodyMedium
                      : theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.outline,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
