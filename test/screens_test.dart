import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:post_reader_favorites/app.dart';
import 'package:post_reader_favorites/app_dependencies.dart';
import 'package:post_reader_favorites/screens/compose_screen.dart';
import 'package:post_reader_favorites/screens/feed_screen.dart';
import 'package:post_reader_favorites/services/favorites_store.dart';
import 'package:post_reader_favorites/services/id_set_store.dart';
import 'package:post_reader_favorites/services/my_posts_store.dart';
import 'package:post_reader_favorites/services/social_api.dart';

// Fixtures for the mocked HTTP client. Odd post ids have no photo, so the
// widget tests never request an image.
final _posts = [
  {'userId': 1, 'id': 1, 'title': 'Alpha post', 'body': 'first body'},
  {'userId': 2, 'id': 3, 'title': 'Beta post', 'body': 'second body'},
];

final _users = [
  for (final entry in [
    (1, 'Leanne Graham', 'Bret'),
    (2, 'Ervin Howell', 'Antonette'),
  ])
    {
      'id': entry.$1,
      'name': entry.$2,
      'username': entry.$3,
      'email': '${entry.$3.toLowerCase()}@example.com',
      'website': 'example.org',
      'company': {'name': 'Acme', 'catchPhrase': 'Moving fast'},
      'address': {'city': 'Springfield'},
    },
];

final _comments = [
  {'postId': 1, 'id': 1, 'name': 'n', 'email': 'e@x.y', 'body': 'b'},
  {'postId': 1, 'id': 2, 'name': 'n', 'email': 'e@x.y', 'body': 'b'},
];

http.Client _mockClient() => MockClient((request) async {
      switch (request.url.path) {
        case '/posts':
          return http.Response(jsonEncode(_posts), 200);
        case '/users':
          return http.Response(jsonEncode(_users), 200);
        case '/comments':
          return http.Response(jsonEncode(_comments), 200);
      }
      return http.Response('not found', 404);
    });

Future<AppDependencies> _openDeps(Directory dir, http.Client client) async {
  Hive.init(dir.path);
  return AppDependencies(
    api: SocialApi(client: client),
    favorites: FavoritesStore(await Hive.openBox<Map>(FavoritesStore.boxName)),
    likes: IdSetStore(await Hive.openBox<bool>(IdSetStore.likesBoxName)),
    following: IdSetStore(await Hive.openBox<bool>(IdSetStore.followingBoxName)),
    myPosts: MyPostsStore(await Hive.openBox<Map>(MyPostsStore.boxName)),
  );
}

void main() {
  testWidgets('feed shows authors, titles and comment counts, and search filters',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('screens_test');
    final deps = (await tester.runAsync(() => _openDeps(dir, _mockClient())))!;

    await tester.pumpWidget(MaterialApp(home: FeedScreen(deps: deps)));
    deps.feed.load();
    await tester.pumpAndSettle();

    expect(find.text('Alpha post'), findsOneWidget);
    expect(find.text('Beta post'), findsOneWidget);
    expect(find.text('Ervin Howell'), findsWidgets);
    expect(find.text('2'), findsOneWidget); // two comments on post 1

    await tester.enterText(find.byType(TextField), 'beta');
    await tester.pumpAndSettle();
    expect(find.text('Alpha post'), findsNothing);
    expect(find.text('Beta post'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('No posts match'), findsOneWidget);

    await tester.runAsync(() => Hive.close());
    dir.deleteSync(recursive: true);
  });

  testWidgets('feed shows the error message and Retry when loading fails',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('screens_test');
    final deps = (await tester.runAsync(
      () => _openDeps(dir, MockClient((_) async => http.Response('', 500))),
    ))!;

    await tester.pumpWidget(MaterialApp(home: FeedScreen(deps: deps)));
    deps.feed.load();
    await tester.pumpAndSettle();

    expect(find.textContaining('status 500'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.runAsync(() => Hive.close());
    dir.deleteSync(recursive: true);
  });

  testWidgets('New post button opens the compose screen', (tester) async {
    final dir = Directory.systemTemp.createTempSync('screens_test');
    final deps = (await tester.runAsync(() => _openDeps(dir, _mockClient())))!;

    await tester.pumpWidget(PulseApp(deps: deps));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New post'));
    await tester.pumpAndSettle();

    expect(find.byType(ComposeScreen), findsOneWidget);

    await tester.runAsync(() => Hive.close());
    dir.deleteSync(recursive: true);
  });

  testWidgets('compose screen requires a title and a body', (tester) async {
    final dir = Directory.systemTemp.createTempSync('screens_test');
    final deps = (await tester.runAsync(() => _openDeps(dir, _mockClient())))!;

    await tester.pumpWidget(MaterialApp(home: ComposeScreen(deps: deps)));
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Body is required'), findsOneWidget);

    await tester.runAsync(() => Hive.close());
    dir.deleteSync(recursive: true);
  });
}
