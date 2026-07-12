/// Big Five trait keys, in the order the API/UI present them.
const List<String> kTraitKeys = [
  'openness',
  'conscientiousness',
  'extraversion',
  'agreeableness',
  'neuroticism',
];

const Map<String, String> kTraitLabels = {
  'openness': 'Openness',
  'conscientiousness': 'Conscientiousness',
  'extraversion': 'Extraversion',
  'agreeableness': 'Agreeableness',
  'neuroticism': 'Neuroticism',
};

const List<String> kExtraSliderKeys = [
  'social_energy',
  'friendship_depth',
  'emotional_expressiveness',
  'routine_adventure',
];

const Map<String, String> kExtraSliderLabels = {
  'social_energy': 'Social energy',
  'friendship_depth': 'Friendship depth',
  'emotional_expressiveness': 'Emotional expressiveness',
  'routine_adventure': 'Routine vs. adventure',
};

const List<String> kValueOptions = [
  'honesty', 'loyalty', 'kindness', 'ambition', 'creativity', 'faith',
  'family', 'fitness', 'learning', 'career', 'humor', 'adventure',
  'peace', 'emotional support', 'respect', 'independence',
];

const List<String> kAvailabilityOptions = [
  'mostly weekdays', 'mostly weekends', 'evenings', 'late night',
  'flexible', 'online only', 'in person preferred',
];

const List<String> kCommunicationStyleOptions = [
  'warm and expressive', 'direct and honest', 'calm and thoughtful',
  'funny and casual', 'practical and solution-focused',
];

const List<String> kConflictStyleOptions = [
  'talk it out quickly', 'take space then discuss', 'avoid conflict',
  'use humor to cool down', 'write thoughts first',
];

const List<String> kAttachmentStyleOptions = [
  'secure', 'anxious', 'avoidant', 'mixed / unsure',
];

const List<String> kSupportStyleOptions = [
  'good listener', 'problem solver', 'motivator', 'fun companion',
  'calm advisor', 'accountability partner',
];

/// The core Profile object the app creates, edits, and matches on.
class Profile {
  final String? id;
  final String name;
  final int age;
  final String city;
  final String bio;
  final List<String> interests;
  final String goals;
  final List<String> values;
  final Map<String, int> traits;
  final Map<String, dynamic> extras;

  const Profile({
    this.id,
    required this.name,
    required this.age,
    required this.city,
    required this.bio,
    required this.interests,
    required this.goals,
    required this.values,
    required this.traits,
    required this.extras,
  });

  factory Profile.empty() => Profile(
        name: '',
        age: 18,
        city: '',
        bio: '',
        interests: const [],
        goals: '',
        values: const [],
        traits: {for (final k in kTraitKeys) k: 50},
        extras: {
          for (final k in kExtraSliderKeys) k: 50,
          'availability': kAvailabilityOptions.first,
          'communication_style': kCommunicationStyleOptions.first,
          'conflict_style': kConflictStyleOptions.first,
          'attachment_style': kAttachmentStyleOptions.first,
          'support_style': kSupportStyleOptions.first,
        },
      );

  factory Profile.fromJson(Map<String, dynamic> json) {
    final rawInterests = json['interests'];
    final interestsList = rawInterests is String
        ? rawInterests.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    return Profile(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 18,
      city: json['city'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      interests: interestsList,
      goals: json['goals'] as String? ?? '',
      values: (json['values'] as List?)?.map((e) => e.toString()).toList() ?? [],
      traits: (json['traits'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
          {for (final k in kTraitKeys) k: 50},
      extras: (json['extras'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'age': age,
        'city': city,
        'bio': bio,
        'interests': interests.join(', '),
        'goals': goals,
        'values': values,
        'traits': traits,
        'extras': extras,
      };

  Profile copyWith({
    String? id,
    String? name,
    int? age,
    String? city,
    String? bio,
    List<String>? interests,
    String? goals,
    List<String>? values,
    Map<String, int>? traits,
    Map<String, dynamic>? extras,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      goals: goals ?? this.goals,
      values: values ?? this.values,
      traits: traits ?? this.traits,
      extras: extras ?? this.extras,
    );
  }
}

/// One entry in a ranked match list.
class MatchResult {
  final String matchId;
  final String name;
  final int age;
  final String city;
  final double score;
  final String summary;
  final List<String> strengths;
  final List<String> watchouts;
  final String suggestedOpener;

  const MatchResult({
    required this.matchId,
    required this.name,
    required this.age,
    required this.city,
    required this.score,
    required this.summary,
    required this.strengths,
    required this.watchouts,
    required this.suggestedOpener,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) => MatchResult(
        matchId: json['match_id']?.toString() ?? '',
        name: json['name'] as String? ?? 'Someone',
        age: (json['age'] as num?)?.toInt() ?? 0,
        city: json['city'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0,
        summary: json['summary'] as String? ?? '',
        strengths: (json['strengths'] as List?)?.map((e) => e.toString()).toList() ?? [],
        watchouts: (json['watchouts'] as List?)?.map((e) => e.toString()).toList() ?? [],
        suggestedOpener: json['suggested_opener'] as String? ?? '',
      );
}

/// Full compatibility breakdown from the compare endpoint. The exact
/// shape of nested breakdown data isn't fixed by the API, so beyond
/// the known fields we keep the raw map and render it generically.
class MatchDetail extends MatchResult {
  final Map<String, dynamic> raw;

  const MatchDetail({
    required super.matchId,
    required super.name,
    required super.age,
    required super.city,
    required super.score,
    required super.summary,
    required super.strengths,
    required super.watchouts,
    required super.suggestedOpener,
    required this.raw,
  });

  factory MatchDetail.fromJson(Map<String, dynamic> json) {
    final base = MatchResult.fromJson(json);
    return MatchDetail(
      matchId: base.matchId,
      name: base.name,
      age: base.age,
      city: base.city,
      score: base.score,
      summary: base.summary,
      strengths: base.strengths,
      watchouts: base.watchouts,
      suggestedOpener: base.suggestedOpener,
      raw: json,
    );
  }

  /// Any nested numeric-scored breakdown maps (e.g. components,
  /// big5_detail, interest_detail) found in the raw payload.
  Map<String, Map<String, dynamic>> get breakdownSections {
    final sections = <String, Map<String, dynamic>>{};
    const knownKeys = ['components', 'big5_detail', 'interest_detail'];
    for (final key in knownKeys) {
      final value = raw[key];
      if (value is Map) {
        sections[key] = value.map((k, v) => MapEntry(k.toString(), v));
      }
    }
    return sections;
  }
}

/// Result of a standalone personality snapshot (POST /api/assessment).
class PersonalitySnapshot {
  final Map<String, TraitLevel> traits;
  final List<String> notes;

  const PersonalitySnapshot({required this.traits, required this.notes});

  factory PersonalitySnapshot.fromJson(Map<String, dynamic> json) {
    final snapshot = (json['snapshot'] as Map?) ?? {};
    return PersonalitySnapshot(
      traits: snapshot.map((k, v) => MapEntry(
            k.toString(),
            TraitLevel(
              score: ((v as Map)['score'] as num?)?.toInt() ?? 50,
              level: v['level']?.toString() ?? '',
            ),
          )),
      notes: (json['notes'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class TraitLevel {
  final int score;
  final String level;
  const TraitLevel({required this.score, required this.level});
}
