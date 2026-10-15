import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app_dependencies.dart';
import 'models/post.dart';

void _showError(ScaffoldMessengerState messenger, String action, HiveError e) {
  messenger.showSnackBar(SnackBar(content: Text('$action: ${e.message}')));
}

Future<void> toggleLike(
  BuildContext context,
  AppDependencies deps,
  Post post,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await deps.likes.toggle(post.id);
  } on HiveError catch (e) {
    _showError(messenger, 'Could not update your like', e);
  }
}

Future<void> toggleFollow(
  BuildContext context,
  AppDependencies deps,
  int userId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await deps.following.toggle(userId);
  } on HiveError catch (e) {
    _showError(messenger, 'Could not update who you follow', e);
  }
}

/// Saves the post, or removes it with an Undo that restores it (and its note).
Future<void> toggleSaved(
  BuildContext context,
  AppDependencies deps,
  Post post,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final existing = deps.favorites.find(post.id);
    if (existing == null) {
      await deps.favorites.add(post);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Saved to your list.')));
      return;
    }
    await deps.favorites.remove(post.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Removed from your saved posts.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                await deps.favorites.restore(existing);
              } on HiveError catch (e) {
                _showError(messenger, 'Could not restore the post', e);
              }
            },
          ),
        ),
      );
  } on HiveError catch (e) {
    _showError(messenger, 'Could not update your saved posts', e);
  } on FormatException catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Your saved post could not be read: ${e.message}')),
    );
  }
}
