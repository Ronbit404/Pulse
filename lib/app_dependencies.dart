import 'package:hive_flutter/hive_flutter.dart';

import 'controllers/feed_controller.dart';
import 'services/favorites_store.dart';
import 'services/id_set_store.dart';
import 'services/my_posts_store.dart';
import 'services/social_api.dart';

/// Everything the screens need: the API, the Hive-backed stores and the feed.
class AppDependencies {
  AppDependencies({
    required this.api,
    required this.favorites,
    required this.likes,
    required this.following,
    required this.myPosts,
  }) : feed = FeedController(
          api: api,
          myPosts: myPosts,
          likes: likes,
          favorites: favorites,
        );

  final SocialApi api;
  final FavoritesStore favorites;
  final IdSetStore likes;
  final IdSetStore following;
  final MyPostsStore myPosts;
  final FeedController feed;

  /// Opens every Hive box. Call after `Hive.initFlutter()`.
  static Future<AppDependencies> open() async {
    final favoritesBox = await Hive.openBox<Map>(FavoritesStore.boxName);
    final likesBox = await Hive.openBox<bool>(IdSetStore.likesBoxName);
    final followingBox = await Hive.openBox<bool>(IdSetStore.followingBoxName);
    final myPostsBox = await Hive.openBox<Map>(MyPostsStore.boxName);
    return AppDependencies(
      api: SocialApi(),
      favorites: FavoritesStore(favoritesBox),
      likes: IdSetStore(likesBox),
      following: IdSetStore(followingBox),
      myPosts: MyPostsStore(myPostsBox),
    );
  }
}
