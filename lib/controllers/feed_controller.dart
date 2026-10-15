import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/favorites_store.dart';
import '../services/id_set_store.dart';
import '../services/my_posts_store.dart';
import '../services/social_api.dart';

/// Holds the feed: posts, people and comment counts from the API, merged with
/// the user's own posts from Hive, plus loading/error/search state.
class FeedController extends ChangeNotifier {
  FeedController({
    required this.api,
    required this.myPosts,
    required this.likes,
    required this.favorites,
  }) : _myPostsListenable = myPosts.listenable() {
    _myPostsListenable.addListener(notifyListeners);
  }

  /// The signed-in account of this prototype: JSONPlaceholder user #1.
  static const int currentUserId = 1;

  final SocialApi api;
  final MyPostsStore myPosts;
  final IdSetStore likes;
  final FavoritesStore favorites;
  final ValueListenable<Box<Map>> _myPostsListenable;

  List<Post> _serverPosts = const [];
  Map<int, User> _users = const {};
  final Map<int, int> _commentCounts = {};
  bool _loading = true;
  bool _inFlight = false;
  String? _error;
  String _query = '';

  bool get isLoading => _loading;
  String? get error => _error;
  String get query => _query;
  bool get hasServerData => _serverPosts.isNotEmpty;
  List<User> get users => _users.values.toList();
  User? get currentUser => _users[currentUserId];

  User? userFor(int id) => _users[id];

  int commentCountFor(int postId) => _commentCounts[postId] ?? 0;

  /// The user's own posts (newest first) followed by the server posts.
  List<Post> get allPosts => [...myPosts.all(), ..._serverPosts];

  /// [allPosts] filtered by the search query (title, body, author name or handle).
  List<Post> get visiblePosts {
    final q = _query.trim().toLowerCase();
    final posts = allPosts;
    if (q.isEmpty) return posts;
    return posts.where((post) {
      final author = _users[post.userId];
      return post.title.toLowerCase().contains(q) ||
          post.body.toLowerCase().contains(q) ||
          (author?.name.toLowerCase().contains(q) ?? false) ||
          (author?.username.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<Post> postsBy(int userId) =>
      allPosts.where((post) => post.userId == userId).toList();

  Future<void> load() async {
    if (_inFlight) return;
    _inFlight = true;
    _loading = _serverPosts.isEmpty;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        api.fetchPosts(),
        api.fetchUsers(),
        api.fetchAllComments(),
      ]);
      _serverPosts = results[0] as List<Post>;
      _users = {for (final user in results[1] as List<User>) user.id: user};
      _commentCounts.clear();
      for (final comment in results[2] as List<Comment>) {
        _commentCounts[comment.postId] =
            (_commentCounts[comment.postId] ?? 0) + 1;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      _inFlight = false;
      notifyListeners();
    }
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  void noteCommentAdded(int postId) {
    _commentCounts[postId] = (_commentCounts[postId] ?? 0) + 1;
    notifyListeners();
  }

  /// Deletes one of the user's own posts and the likes/saves that point at it.
  Future<void> deleteOwnPost(Post post) async {
    if (!post.isLocal) {
      throw StateError('Only posts written on this device can be deleted.');
    }
    await myPosts.remove(post.id);
    await likes.remove(post.id);
    await favorites.remove(post.id);
  }

  @override
  void dispose() {
    _myPostsListenable.removeListener(notifyListeners);
    super.dispose();
  }
}
