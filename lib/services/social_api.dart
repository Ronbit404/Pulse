import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';

/// A failure from the API, with a message that is safe to show to users.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => 'ApiException: $message';
}

/// Client for https://jsonplaceholder.typicode.com.
class SocialApi {
  SocialApi({http.Client? client}) : _client = client ?? http.Client();

  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<List<Post>> fetchPosts() => _guard('Loading posts', () async {
        final items = await _getList('/posts', 'Loading posts');
        return items.map(Post.fromMap).toList();
      });

  Future<List<User>> fetchUsers() => _guard('Loading people', () async {
        final items = await _getList('/users', 'Loading people');
        return items.map(User.fromMap).toList();
      });

  /// Every comment on every post (used for the comment counts in the feed).
  Future<List<Comment>> fetchAllComments() =>
      _guard('Loading comments', () async {
        final items = await _getList('/comments', 'Loading comments');
        return items.map(Comment.fromMap).toList();
      });

  Future<List<Comment>> fetchPostComments(int postId) =>
      _guard('Loading comments', () async {
        final items =
            await _getList('/posts/$postId/comments', 'Loading comments');
        return items.map(Comment.fromMap).toList();
      });

  /// POST /posts. Succeeds only when the server answers 201.
  Future<void> createPost({
    required int userId,
    required String title,
    required String body,
  }) =>
      _guard('Publishing the post', () async {
        await _postObject(
          '/posts',
          {'userId': userId, 'title': title, 'body': body},
          'Publishing the post',
        );
      });

  /// POST /comments. Succeeds only on status 201 and returns the server's echo.
  Future<Comment> createComment({
    required int postId,
    required String name,
    required String email,
    required String body,
  }) =>
      _guard('Sending the comment', () async {
        final created = await _postObject(
          '/comments',
          {'postId': postId, 'name': name, 'email': email, 'body': body},
          'Sending the comment',
        );
        return Comment.fromMap(created);
      });

  Future<List<Map<String, dynamic>>> _getList(
    String path,
    String action,
  ) async {
    final response = await _client.get(_uri(path)).timeout(_timeout);
    if (response.statusCode != 200) {
      throw ApiException(
        '$action failed: the server responded with status '
        '${response.statusCode} instead of 200.',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw ApiException('$action failed: the server returned an unexpected format.');
    }
    return decoded.map((item) {
      if (item is! Map) {
        throw const FormatException('Expected a list of objects.');
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  Future<Map<String, dynamic>> _postObject(
    String path,
    Map<String, dynamic> payload,
    String action,
  ) async {
    final response = await _client
        .post(
          _uri(path),
          headers: const {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(payload),
        )
        .timeout(_timeout);
    if (response.statusCode != 201) {
      throw ApiException(
        '$action failed: the server responded with status '
        '${response.statusCode} instead of 201.',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw ApiException('$action failed: the server returned an unexpected format.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  /// Maps transport and parsing failures to [ApiException].
  Future<T> _guard<T>(String action, Future<T> Function() run) async {
    try {
      return await run();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        '$action timed out. Check your connection and try again.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        '$action failed: could not reach the server (${e.message}).',
      );
    } on FormatException catch (e) {
      throw ApiException(
        '$action failed: the server sent invalid data (${e.message}).',
      );
    }
  }
}
