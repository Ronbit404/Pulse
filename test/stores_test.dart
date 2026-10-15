import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:post_reader_favorites/models/post.dart';
import 'package:post_reader_favorites/services/favorites_store.dart';
import 'package:post_reader_favorites/services/id_set_store.dart';
import 'package:post_reader_favorites/services/my_posts_store.dart';

void main() {
  late Directory dir;

  const post = Post(id: 5, userId: 2, title: 'title', body: 'body');

  setUp(() {
    dir = Directory.systemTemp.createTempSync('stores_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  group('FavoritesStore', () {
    late Box<Map> box;
    late FavoritesStore store;

    setUp(() async {
      box = await Hive.openBox<Map>(FavoritesStore.boxName);
      store = FavoritesStore(box);
    });

    test('add stores a post once, keyed by id', () async {
      expect(await store.add(post), isTrue);
      expect(await store.add(post), isFalse);
      expect(store.all(), hasLength(1));
      expect(store.contains(5), isTrue);
      expect(store.count, 1);
    });

    test('updateNote changes only the note', () async {
      await store.add(post);
      await store.updateNote(5, 'remember this');
      final saved = store.find(5)!;
      expect(saved.note, 'remember this');
      expect(saved.post.title, 'title');
    });

    test('updateNote throws for a post that is not saved', () {
      expect(() => store.updateNote(99, 'x'), throwsStateError);
    });

    test('remove deletes the post and restore brings it back with its note',
        () async {
      await store.add(post);
      await store.updateNote(5, 'kept');
      final saved = store.find(5)!;

      await store.remove(5);
      expect(store.find(5), isNull);

      await store.restore(saved);
      expect(store.find(5)!.note, 'kept');
    });

    test('favorites persist after the box is closed and reopened', () async {
      await store.add(post);
      await store.updateNote(5, 'kept');
      await box.close();

      final reopened = await Hive.openBox<Map>(FavoritesStore.boxName);
      final saved = FavoritesStore(reopened).all().single;
      expect(saved.post.id, 5);
      expect(saved.note, 'kept');
    });
  });

  group('IdSetStore', () {
    test('toggle adds then removes an id', () async {
      final store = IdSetStore(await Hive.openBox<bool>(IdSetStore.likesBoxName));
      expect(await store.toggle(3), isTrue);
      expect(store.contains(3), isTrue);
      expect(store.count, 1);
      expect(await store.toggle(3), isFalse);
      expect(store.contains(3), isFalse);
    });

    test('ids persist after the box is reopened', () async {
      final box = await Hive.openBox<bool>(IdSetStore.followingBoxName);
      await IdSetStore(box).toggle(4);
      await box.close();

      final reopened = await Hive.openBox<bool>(IdSetStore.followingBoxName);
      expect(IdSetStore(reopened).contains(4), isTrue);
    });
  });

  group('MyPostsStore', () {
    late Box<Map> box;
    late MyPostsStore store;

    setUp(() async {
      box = await Hive.openBox<Map>(MyPostsStore.boxName);
      store = MyPostsStore(box);
    });

    test('assigns local ids from 1000 and lists newest first', () async {
      final first = await store.add(userId: 1, title: 'a', body: 'x');
      final second = await store.add(userId: 1, title: 'b', body: 'y');
      expect(first.id, Post.firstLocalId);
      expect(second.id, Post.firstLocalId + 1);
      expect(first.isLocal, isTrue);
      expect(store.all().map((p) => p.title), ['b', 'a']);
    });

    test('remove deletes a post', () async {
      final created = await store.add(userId: 1, title: 'a', body: 'x');
      await store.remove(created.id);
      expect(store.all(), isEmpty);
    });

    test('posts persist after the box is reopened', () async {
      await store.add(userId: 1, title: 'kept', body: 'x');
      await box.close();

      final reopened = await Hive.openBox<Map>(MyPostsStore.boxName);
      expect(MyPostsStore(reopened).all().single.title, 'kept');
    });
  });
}
