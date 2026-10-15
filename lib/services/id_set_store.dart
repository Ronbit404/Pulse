import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A persisted set of ids (liked post ids, followed user ids).
class IdSetStore {
  IdSetStore(this._box);

  static const String likesBoxName = 'likesBox';
  static const String followingBoxName = 'followingBox';

  final Box<bool> _box;

  ValueListenable<Box<bool>> listenable({List<int>? keys}) =>
      _box.listenable(keys: keys);

  int get count => _box.length;

  bool contains(int id) => _box.containsKey(id);

  /// Adds the id if absent, removes it if present. Returns true if it is now in the set.
  Future<bool> toggle(int id) async {
    if (_box.containsKey(id)) {
      await _box.delete(id);
      return false;
    }
    await _box.put(id, true);
    return true;
  }

  Future<void> remove(int id) => _box.delete(id);
}
