import 'dart:convert';
import 'dart:typed_data';

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

const _placeholderNames = {'someone', 'somebody', 'unknown', 'n/a', 'na'};

String personNameFrom(Map<String, dynamic> json, {String? city}) {
  for (final key in ['name', 'full_name', 'profile_name', 'candidate_name', 'display_name']) {
    final value = json[key]?.toString().trim() ?? '';
    if (value.isNotEmpty && !_placeholderNames.contains(value.toLowerCase())) {
      return value;
    }
  }
  final nested = json['profile'] ?? json['match'] ?? json['candidate'];
  if (nested is Map<String, dynamic>) {
    return personNameFrom(nested, city: city ?? nested['city']?.toString());
  }
  final fallbackCity = (city ?? json['city']?.toString() ?? '').trim();
  if (fallbackCity.isNotEmpty) return fallbackCity;
  return '';
}

String displayNameFor(String name, String city, {String fallback = 'Match'}) {
  final trimmed = name.trim();
  if (trimmed.isNotEmpty && !_placeholderNames.contains(trimmed.toLowerCase())) {
    return trimmed;
  }
  final cityTrim = city.trim();
  if (cityTrim.isNotEmpty) return cityTrim;
  return fallback;
}

String withRealName(String text, String name) {
  final replacement = name.trim().isNotEmpty ? name.trim() : 'this match';
  return text.replaceAll(RegExp(r'\bSomeone\b', caseSensitive: false), replacement);
}

List<String> withRealNameList(List<String> items, String name) {
  return items.map((item) => withRealName(item, name)).toList();
}

Uint8List? decodeProfilePhoto(dynamic raw) {
  if (raw == null) return null;
  var value = raw.toString().trim();
  if (value.isEmpty) return null;
  if (value.contains(',')) value = value.split(',').last;
  try {
    final bytes = base64Decode(value);
    return bytes.isEmpty ? null : bytes;
  } catch (_) {
    return null;
  }
}

Uint8List? photoFromJson(Map<String, dynamic> json) {
  final extras = json['extras'];
  final fromExtras = extras is Map ? extras['photo'] : null;
  return decodeProfilePhoto(json['photo'] ?? json['image'] ?? json['avatar'] ?? fromExtras);
}

Map<String, dynamic> _extrasFromJson(Map<String, dynamic> map) {
  final extras = (map['extras'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? <String, dynamic>{};
  final photo = map['photo'] ?? map['image'] ?? map['avatar'] ?? extras['photo'];
  if (photo != null && extras['photo'] == null) {
    extras['photo'] = photo;
  }
  return extras;
}

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
    final nested = json['profile'];
    final map = nested is Map
        ? {'id': json['id'], ...Map<String, dynamic>.from(nested)}
        : json;
    final rawInterests = map['interests'];
    final interestsList = rawInterests is String
        ? rawInterests.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    return Profile(
      id: map['id'] as String? ?? json['id'] as String?,
      name: personNameFrom(map, city: map['city']?.toString()),
      age: (map['age'] as num?)?.toInt() ?? 18,
      city: map['city'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      interests: interestsList,
      goals: map['goals'] as String? ?? '',
      values: (map['values'] as List?)?.map((e) => e.toString()).toList() ?? [],
      traits: (map['traits'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
          {for (final k in kTraitKeys) k: 50},
      extras: _extrasFromJson(map),
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

  Uint8List? get photoBytes => photoFromJson({'extras': extras, 'photo': extras['photo']});

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
  final Uint8List? photoBytes;

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
    this.photoBytes,
  });

  bool get hasRealName {
    final trimmed = name.trim();
    return trimmed.isNotEmpty && !_placeholderNames.contains(trimmed.toLowerCase());
  }

  String get displayName => displayNameFor(name, city);

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    final nested = json['match'] is Map
        ? Map<String, dynamic>.from(json['match'] as Map)
        : json;
    final name = personNameFrom({...json, ...nested}, city: nested['city']?.toString() ?? json['city']?.toString());
    final city = nested['city'] as String? ?? json['city'] as String? ?? '';
    final shown = displayNameFor(name, city, fallback: 'this match');
    return MatchResult(
      matchId: (json['match_id'] ?? nested['match_id'] ?? nested['id'])?.toString() ?? '',
      name: name,
      age: (nested['age'] as num?)?.toInt() ?? (json['age'] as num?)?.toInt() ?? 0,
      city: city,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      summary: withRealName(json['summary'] as String? ?? '', shown),
      strengths: withRealNameList((json['strengths'] as List?)?.map((e) => e.toString()).toList() ?? [], shown),
      watchouts: withRealNameList((json['watchouts'] as List?)?.map((e) => e.toString()).toList() ?? [], shown),
      suggestedOpener: withRealName(json['suggested_opener'] as String? ?? '', shown),
      photoBytes: photoFromJson(nested) ?? photoFromJson(json),
    );
  }

  MatchResult copyWith({
    String? matchId,
    String? name,
    int? age,
    String? city,
    double? score,
    String? summary,
    List<String>? strengths,
    List<String>? watchouts,
    String? suggestedOpener,
    Uint8List? photoBytes,
  }) {
    final resolvedName = name ?? this.name;
    final resolvedCity = city ?? this.city;
    final shown = displayNameFor(resolvedName, resolvedCity, fallback: 'this match');
    return MatchResult(
      matchId: matchId ?? this.matchId,
      name: resolvedName,
      age: age ?? this.age,
      city: resolvedCity,
      score: score ?? this.score,
      summary: summary ?? withRealName(this.summary, shown),
      strengths: strengths ?? withRealNameList(this.strengths, shown),
      watchouts: watchouts ?? withRealNameList(this.watchouts, shown),
      suggestedOpener: suggestedOpener ?? withRealName(this.suggestedOpener, shown),
      photoBytes: photoBytes ?? this.photoBytes,
    );
  }
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
    super.photoBytes,
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
      photoBytes: base.photoBytes,
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
