import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/local_user.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_db.dart';
import '../services/auth_service.dart';
import '../services/local_store.dart';
import '../services/photo_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final localStoreProvider = Provider<LocalStore>((ref) => LocalStore());
final authDbProvider = Provider<AuthDb>((ref) => AuthDb());

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(authDbProvider), ref.watch(localStoreProvider));
});

/// The signed-in local account, restored from SQLite on splash.
final currentUserProvider = StateProvider<LocalUser?>((ref) => null);

/// The signed-in profile id linked to the local account.
/// Null until the splash screen (or onboarding) resolves it.
final profileIdProvider = StateProvider<String?>((ref) => null);

final photoServiceProvider = Provider<PhotoService>((ref) => PhotoService());

/// The current user's saved profile, refetched whenever the id changes.
final myProfileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final id = ref.watch(profileIdProvider);
  if (id == null) return null;
  final api = ref.watch(apiServiceProvider);
  final profile = await api.getProfile(id);
  final localPhoto = await ref.watch(photoServiceProvider).readLocal(id);
  if (localPhoto == null) return profile;
  return profile.copyWith(extras: ref.read(photoServiceProvider).extrasWithPhoto(profile.extras, localPhoto));
});

/// Ranked matches for the current user.
final matchesProvider = FutureProvider.autoDispose<List<MatchResult>>((ref) async {
  final id = ref.watch(profileIdProvider);
  if (id == null) return [];
  final api = ref.watch(apiServiceProvider);
  final matches = await api.getMatches(id, topK: 12);
  return Future.wait(matches.map((match) => _enrichMatch(api, match)));
});

final matchDetailProvider =
    FutureProvider.autoDispose.family<MatchDetail, ({String myId, String candidateId})>((ref, ids) async {
  final api = ref.watch(apiServiceProvider);
  final detail = await api.compare(ids.myId, ids.candidateId);
  if (detail.hasRealName && detail.photoBytes != null) return detail;
  try {
    final profile = await api.getProfile(ids.candidateId);
    final name = detail.hasRealName
        ? detail.name
        : personNameFrom({'name': profile.name, 'city': profile.city}, city: profile.city);
    final shown = displayNameFor(name, profile.city, fallback: detail.displayName);
    return MatchDetail(
      matchId: detail.matchId,
      name: shown,
      age: detail.age > 0 ? detail.age : profile.age,
      city: detail.city.isNotEmpty ? detail.city : profile.city,
      score: detail.score,
      summary: withRealName(detail.summary, shown),
      strengths: withRealNameList(detail.strengths, shown),
      watchouts: withRealNameList(detail.watchouts, shown),
      suggestedOpener: withRealName(detail.suggestedOpener, shown),
      photoBytes: detail.photoBytes ?? profile.photoBytes,
      raw: detail.raw,
    );
  } catch (_) {
    return detail;
  }
});

Future<MatchResult> _enrichMatch(ApiService api, MatchResult match) async {
  if (match.hasRealName && match.photoBytes != null) return match;
  if (match.matchId.isEmpty) return match;
  try {
    final profile = await api.getProfile(match.matchId);
    final name = match.hasRealName
        ? match.name
        : personNameFrom({'name': profile.name, 'city': profile.city}, city: profile.city);
    final shown = displayNameFor(name, profile.city, fallback: match.displayName);
    return match.copyWith(
      name: shown,
      age: match.age > 0 ? match.age : profile.age,
      city: match.city.isNotEmpty ? match.city : profile.city,
      photoBytes: match.photoBytes ?? profile.photoBytes,
      summary: withRealName(match.summary, shown),
      strengths: withRealNameList(match.strengths, shown),
      watchouts: withRealNameList(match.watchouts, shown),
      suggestedOpener: withRealName(match.suggestedOpener, shown),
    );
  } catch (_) {
    return match;
  }
}

/// Whether the admin panel has been unlocked for this app session.
/// Intentionally NOT persisted — every fresh launch requires the PIN again.
final adminUnlockedProvider = StateProvider<bool>((ref) => false);

/// Every profile in the system — admin panel only.
final allProfilesProvider = FutureProvider.autoDispose<List<Profile>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getAllProfiles();
});

/// Mutable draft used across the onboarding / edit-profile flow.
class ProfileDraftNotifier extends StateNotifier<Profile> {
  ProfileDraftNotifier([Profile? initial]) : super(initial ?? Profile.empty());

  void reset([Profile? profile]) => state = profile ?? Profile.empty();

  void updateBasics({String? name, int? age, String? city, String? bio, String? goals, List<String>? interests}) {
    state = state.copyWith(
      name: name ?? state.name,
      age: age ?? state.age,
      city: city ?? state.city,
      bio: bio ?? state.bio,
      goals: goals ?? state.goals,
      interests: interests ?? state.interests,
    );
  }

  void updateTrait(String key, int value) {
    state = state.copyWith(traits: {...state.traits, key: value});
  }

  void updateExtra(String key, dynamic value) {
    state = state.copyWith(extras: {...state.extras, key: value});
  }

  void toggleValue(String value) {
    final current = List<String>.from(state.values);
    if (current.contains(value)) {
      current.remove(value);
    } else {
      current.add(value);
    }
    state = state.copyWith(values: current);
  }
}

final profileDraftProvider = StateNotifierProvider<ProfileDraftNotifier, Profile>(
  (ref) => ProfileDraftNotifier(),
);

Future<void> applySession(WidgetRef ref, LocalUser user) async {
  ref.read(currentUserProvider.notifier).state = user;
  ref.read(profileIdProvider.notifier).state = user.profileId;
}

Future<void> clearSessionState(WidgetRef ref) async {
  ref.read(currentUserProvider.notifier).state = null;
  ref.read(profileIdProvider.notifier).state = null;
  ref.read(profileDraftProvider.notifier).reset();
  ref.read(adminUnlockedProvider.notifier).state = false;
}
