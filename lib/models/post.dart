import 'json_field.dart';

/// A post, either from https://jsonplaceholder.typicode.com/posts or written
/// on this device (local posts have ids from [firstLocalId] upwards).
class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  /// JSONPlaceholder ids stop at 100, so anything from here up is local.
  static const int firstLocalId = 1000;

  final int id;
  final int userId;
  final String title;
  final String body;

  bool get isLocal => id >= firstLocalId;

  /// JSONPlaceholder posts carry no pictures, so every other server post is
  /// shown with a deterministic photo from picsum.photos.
  bool get hasImage => !isLocal && id.isEven;

  String get imageUrl => 'https://picsum.photos/seed/pulse-$id/800/450';

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: jsonField<int>(map, 'id', 'Post'),
      userId: jsonField<int>(map, 'userId', 'Post'),
      title: jsonField<String>(map, 'title', 'Post'),
      body: jsonField<String>(map, 'body', 'Post'),
    );
  }

  /// Builds a post from the route arguments passed to the details screen.
  factory Post.fromArguments(Object? arguments) {
    if (arguments is! Map) {
      throw const FormatException('No post details were provided.');
    }
    return Post.fromMap(Map<String, dynamic>.from(arguments));
  }

  Map<String, dynamic> toMap() =>
      {'id': id, 'userId': userId, 'title': title, 'body': body};
}

/// A post saved in the Hive favorites box, with the user's personal note.
class FavoritePost {
  const FavoritePost({required this.post, required this.note});

  final Post post;

  /// Empty when the user has not written a note yet.
  final String note;

  factory FavoritePost.fromMap(Map<dynamic, dynamic> map) {
    final typed = Map<String, dynamic>.from(map);
    final note = typed['note'];
    return FavoritePost(
      post: Post.fromMap(typed),
      note: note is String ? note : '',
    );
  }

  Map<String, dynamic> toMap() => {...post.toMap(), 'note': note};

  FavoritePost copyWith({String? note}) =>
      FavoritePost(post: post, note: note ?? this.note);
}
