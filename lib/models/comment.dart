import 'json_field.dart';

/// A comment from https://jsonplaceholder.typicode.com/comments.
class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.name,
    required this.email,
    required this.body,
  });

  final int id;
  final int postId;
  final String name;
  final String email;
  final String body;

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: jsonField<int>(map, 'id', 'Comment'),
      postId: jsonField<int>(map, 'postId', 'Comment'),
      name: jsonField<String>(map, 'name', 'Comment'),
      email: jsonField<String>(map, 'email', 'Comment'),
      body: jsonField<String>(map, 'body', 'Comment'),
    );
  }
}
