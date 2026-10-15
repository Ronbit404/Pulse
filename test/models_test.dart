import 'package:flutter_test/flutter_test.dart';
import 'package:post_reader_favorites/models/comment.dart';
import 'package:post_reader_favorites/models/post.dart';
import 'package:post_reader_favorites/models/user.dart';
import 'package:post_reader_favorites/widgets/user_avatar.dart';

void main() {
  group('Post', () {
    const map = {'id': 3, 'userId': 1, 'title': 't', 'body': 'b'};

    test('fromMap and toMap round-trip', () {
      expect(Post.fromMap(map).toMap(), map);
    });

    test('fromMap rejects a missing userId', () {
      expect(
        () => Post.fromMap({'id': 1, 'title': 't', 'body': 'b'}),
        throwsFormatException,
      );
    });

    test('fromMap rejects a non-string title', () {
      expect(
        () => Post.fromMap({'id': 1, 'userId': 1, 'title': 5, 'body': 'b'}),
        throwsFormatException,
      );
    });

    test('fromArguments rejects null arguments', () {
      expect(() => Post.fromArguments(null), throwsFormatException);
    });

    test('fromArguments reads the post map', () {
      expect(Post.fromArguments(map).id, 3);
    });

    test('server posts below the local range are not local', () {
      expect(const Post(id: 100, userId: 1, title: 't', body: 'b').isLocal, isFalse);
      expect(const Post(id: 1000, userId: 1, title: 't', body: 'b').isLocal, isTrue);
    });

    test('only even-numbered server posts get a photo', () {
      expect(const Post(id: 2, userId: 1, title: 't', body: 'b').hasImage, isTrue);
      expect(const Post(id: 3, userId: 1, title: 't', body: 'b').hasImage, isFalse);
      expect(const Post(id: 1002, userId: 1, title: 't', body: 'b').hasImage, isFalse);
    });
  });

  group('FavoritePost', () {
    test('defaults to an empty note when none is stored', () {
      final favorite = FavoritePost.fromMap(
        {'id': 1, 'userId': 1, 'title': 't', 'body': 'b'},
      );
      expect(favorite.note, '');
    });

    test('copyWith replaces only the note', () {
      const favorite = FavoritePost(
        post: Post(id: 1, userId: 1, title: 't', body: 'b'),
        note: '',
      );
      final updated = favorite.copyWith(note: 'hello');
      expect(updated.note, 'hello');
      expect(updated.post.id, 1);
    });
  });

  group('User', () {
    final json = {
      'id': 1,
      'name': 'Leanne Graham',
      'username': 'Bret',
      'email': 'a@b.c',
      'website': 'hildegard.org',
      'company': {'name': 'Romaguera', 'catchPhrase': 'Multi-layered'},
      'address': {'city': 'Gwenborough'},
    };

    test('fromMap reads nested company and address', () {
      final user = User.fromMap(json);
      expect(user.companyName, 'Romaguera');
      expect(user.city, 'Gwenborough');
    });

    test('fromMap rejects a missing company', () {
      expect(
        () => User.fromMap({...json}..remove('company')),
        throwsFormatException,
      );
    });
  });

  test('Comment.fromMap rejects a missing postId', () {
    expect(
      () => Comment.fromMap({'id': 1, 'name': 'n', 'email': 'e', 'body': 'b'}),
      throwsFormatException,
    );
  });

  group('UserAvatar', () {
    test('initialsOf uses the first two words', () {
      expect(UserAvatar.initialsOf('Leanne Graham'), 'LG');
      expect(UserAvatar.initialsOf('  madonna '), 'M');
      expect(UserAvatar.initialsOf(''), '?');
    });

    test('colorFor is stable for the same name', () {
      expect(UserAvatar.colorFor('Bret'), UserAvatar.colorFor('Bret'));
    });
  });
}
