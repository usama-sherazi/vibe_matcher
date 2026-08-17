class LocalUser {
  const LocalUser({
    required this.id,
    required this.email,
    this.profileId,
  });

  final int id;
  final String email;
  final String? profileId;

  LocalUser copyWith({int? id, String? email, String? profileId, bool clearProfileId = false}) {
    return LocalUser(
      id: id ?? this.id,
      email: email ?? this.email,
      profileId: clearProfileId ? null : (profileId ?? this.profileId),
    );
  }

  factory LocalUser.fromMap(Map<String, dynamic> map) {
    final rawProfile = map['profile_id'] as String?;
    return LocalUser(
      id: map['id'] as int,
      email: map['email'] as String,
      profileId: (rawProfile == null || rawProfile.isEmpty) ? null : rawProfile,
    );
  }
}
