import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/post.dart';

/// Posts written on this device. JSONPlaceholder acknowledges new posts with
/// status 201 but never stores them, so the app keeps the user's own posts here.
class MyPostsStore {
  MyPostsStore(this._box);

  static const String boxName = 'myPostsBox';

  final Box<Map> _box;

  ValueListenable<Box<Map>> listenable() => _box.listenable();

  /// Newest first. Throws [FormatException] if a stored entry is corrupt.
  List<Post> all() {
    final posts = _box.values
        .map((stored) => Post.fromMap(Map<String, dynamic>.from(stored)))
        .toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    return posts;
  }

  Future<Post> add({
    required int userId,
    required String title,
    required String body,
  }) async {
    final lastId = _box.keys
        .cast<int>()
        .fold<int>(Post.firstLocalId - 1, (a, b) => math.max(a, b));
    final post = Post(id: lastId + 1, userId: userId, title: title, body: body);
    await _box.put(post.id, post.toMap());
    return post;
  }

  Future<void> remove(int postId) => _box.delete(postId);
}
