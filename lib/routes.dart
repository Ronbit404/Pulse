/// Named routes used with `Navigator.pushNamed`.
abstract final class AppRoutes {
  /// Home shell: Feed, Saved and Profile tabs.
  static const String home = '/';

  /// Arguments: the post as a map (`Post.toMap()`).
  static const String details = '/details';

  /// The saved-posts list.
  static const String favorites = '/favorites';

  /// Write a new post. Pops with the created `Post`.
  static const String compose = '/compose';

  /// Arguments: the user id (`int`).
  static const String profile = '/profile';
}
