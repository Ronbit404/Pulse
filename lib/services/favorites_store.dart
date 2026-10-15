import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/post.dart';

/// CRUD access to saved posts. The post id is the box key, so a post can
/// never be stored twice.
class FavoritesStore {
  FavoritesStore(this._box);

  static const String boxName = 'favoritesBox';

  final Box<Map> _box;

  /// Notifies when the box (or only the given post ids) changes.
  ValueListenable<Box<Map>> listenable({List<int>? keys}) =>
      _box.listenable(keys: keys);

  int get count => _box.length;

  bool contains(int postId) => _box.containsKey(postId);

  /// Returns the saved entry, or null when the post is not saved.
  /// Throws [FormatException] if the stored entry is corrupt.
  FavoritePost? find(int postId) {
    final stored = _box.get(postId);
    return stored == null ? null : FavoritePost.fromMap(stored);
  }

  /// Create. Returns false, without writing, if the post is already saved.
  Future<bool> add(Post post) async {
    if (_box.containsKey(post.id)) return false;
    await _box.put(post.id, FavoritePost(post: post, note: '').toMap());
    return true;
  }

  /// Puts back an entry that was removed (used by "Undo"), keeping its note.
  Future<void> restore(FavoritePost favorite) =>
      _box.put(favorite.post.id, favorite.toMap());

  /// Read. Throws [FormatException] if a stored entry is corrupt.
  List<FavoritePost> all() {
    final items = _box.values.map(FavoritePost.fromMap).toList()
      ..sort((a, b) => b.post.id.compareTo(a.post.id));
    return items;
  }

  /// Update the personal note of a saved post.
  Future<void> updateNote(int postId, String note) async {
    final current = find(postId);
    if (current == null) {
      throw StateError('Post $postId is no longer in your saved posts.');
    }
    await _box.put(postId, current.copyWith(note: note).toMap());
  }

  /// Delete.
  Future<void> remove(int postId) => _box.delete(postId);
}
