import '../../data/json_api.dart';

/// A marketplace user: the logged-in user, or a listing's author (provider).
class User {
  const User({required this.id, required this.displayName, this.email});

  /// Maps a `user` or `currentUser` resource. [email] is only present on the
  /// current user.
  factory User.fromJsonApi(JsonApiResource resource) {
    final profile = resource.attributes['profile'];
    final profileMap = profile is Map ? profile : const {};
    return User(
      id: resource.id,
      displayName:
          (profileMap['displayName'] ?? profileMap['abbreviatedName'] ?? '')
              as String,
      email: resource.attributes['email'] as String?,
    );
  }

  final String id;
  final String displayName;
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is User &&
      other.id == id &&
      other.displayName == displayName &&
      other.email == email;

  @override
  int get hashCode => Object.hash(id, displayName, email);

  @override
  String toString() => 'User($id, $displayName)';
}
