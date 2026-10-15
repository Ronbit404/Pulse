import 'json_field.dart';

/// A user from https://jsonplaceholder.typicode.com/users.
class User {
  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.website,
    required this.companyName,
    required this.catchPhrase,
    required this.city,
  });

  final int id;
  final String name;
  final String username;
  final String email;
  final String website;
  final String companyName;
  final String catchPhrase;
  final String city;

  factory User.fromMap(Map<String, dynamic> map) {
    final company = jsonField<Map>(map, 'company', 'User');
    final address = jsonField<Map>(map, 'address', 'User');
    return User(
      id: jsonField<int>(map, 'id', 'User'),
      name: jsonField<String>(map, 'name', 'User'),
      username: jsonField<String>(map, 'username', 'User'),
      email: jsonField<String>(map, 'email', 'User'),
      website: jsonField<String>(map, 'website', 'User'),
      companyName: jsonField<String>(company, 'name', 'User company'),
      catchPhrase: jsonField<String>(company, 'catchPhrase', 'User company'),
      city: jsonField<String>(address, 'city', 'User address'),
    );
  }
}
