/// Reads [key] from a decoded JSON [map], requiring it to be a [T].
/// Throws a [FormatException] naming the [owner] model when it is missing or mistyped.
T jsonField<T>(Map<dynamic, dynamic> map, String key, String owner) {
  final value = map[key];
  if (value is! T) {
    throw FormatException('$owner is missing a valid "$key".');
  }
  return value;
}
