import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:post_reader_favorites/services/social_api.dart';

void main() {
  group('fetching', () {
    test('fetchPosts parses a 200 response', () async {
      final api = SocialApi(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.toString(), '${SocialApi.baseUrl}/posts');
          return http.Response(
            jsonEncode([
              {'userId': 1, 'id': 1, 'title': 'first', 'body': 'one'},
              {'userId': 2, 'id': 2, 'title': 'second', 'body': 'two'},
            ]),
            200,
          );
        }),
      );
      final posts = await api.fetchPosts();
      expect(posts.map((p) => p.title), ['first', 'second']);
      expect(posts.last.userId, 2);
    });

    test('fetchPostComments requests the post-specific path', () async {
      final api = SocialApi(
        client: MockClient((request) async {
          expect(request.url.path, '/posts/7/comments');
          return http.Response(
            jsonEncode([
              {'postId': 7, 'id': 31, 'name': 'n', 'email': 'e@x.y', 'body': 'b'},
            ]),
            200,
          );
        }),
      );
      expect((await api.fetchPostComments(7)).single.id, 31);
    });

    test('throws ApiException mentioning the status on non-200', () async {
      final api = SocialApi(
        client: MockClient((_) async => http.Response('oops', 500)),
      );
      expect(
        api.fetchPosts(),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', contains('500')),
        ),
      );
    });

    test('throws ApiException on network failure', () async {
      final api = SocialApi(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      expect(api.fetchUsers(), throwsA(isA<ApiException>()));
    });

    test('throws ApiException on malformed JSON', () async {
      final api = SocialApi(
        client: MockClient((_) async => http.Response('not json', 200)),
      );
      expect(api.fetchPosts(), throwsA(isA<ApiException>()));
    });

    test('throws ApiException when a post is missing fields', () async {
      final api = SocialApi(
        client: MockClient(
          (_) async => http.Response(jsonEncode([{'id': 1}]), 200),
        ),
      );
      expect(api.fetchPosts(), throwsA(isA<ApiException>()));
    });
  });

  group('creating', () {
    test('createPost sends JSON and completes on 201', () async {
      var sent = false;
      final api = SocialApi(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(jsonDecode(request.body), {'userId': 1, 'title': 'T', 'body': 'B'});
          sent = true;
          return http.Response(
            jsonEncode({'id': 101, 'userId': 1, 'title': 'T', 'body': 'B'}),
            201,
          );
        }),
      );
      await api.createPost(userId: 1, title: 'T', body: 'B');
      expect(sent, isTrue);
    });

    test('createPost throws ApiException when status is not 201', () async {
      final api = SocialApi(
        client: MockClient((_) async => http.Response('{}', 400)),
      );
      expect(
        api.createPost(userId: 1, title: 'T', body: 'B'),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', contains('400')),
        ),
      );
    });

    test('createComment returns the comment on 201', () async {
      final api = SocialApi(
        client: MockClient((request) async {
          expect(request.url.path, '/comments');
          expect(jsonDecode(request.body)['postId'], 4);
          return http.Response(
            jsonEncode({
              'id': 501,
              'postId': 4,
              'name': 'N',
              'email': 'e@x.y',
              'body': 'hello',
            }),
            201,
          );
        }),
      );
      final comment = await api.createComment(
        postId: 4,
        name: 'N',
        email: 'e@x.y',
        body: 'hello',
      );
      expect(comment.body, 'hello');
    });
  });
}
