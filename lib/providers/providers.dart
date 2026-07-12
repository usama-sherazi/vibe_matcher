import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/local_store.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final localStoreProvider = Provider<LocalStore>((ref) => LocalStore());

/// The signed-in profile id (there's no auth layer yet — this id
/// standing in for a session, per the API guide). Null until the
/// splash screen resolves it from local storage.
final profileIdProvider = StateProvider<String?>((ref) => null);

/// The current user's saved profile, refetched whenever the id changes.
final myProfileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final id = ref.watch(profileIdProvider);
  if (id == null) return null;
  final api = ref.watch(apiServiceProvider);
  return api.getProfile(id);
});

/// Ranked matches for the current user.
final matchesProvider = FutureProvider.autoDispose<List<MatchResult>>((ref) async {
  final id = ref.watch(profileIdProvider);
  if (id == null) return [];
  final api = ref.watch(apiServiceProvider);
  return api.getMatches(id, topK: 12);
});

/// Whether the admin panel has been unlocked for this app session.
/// Intentionally NOT persisted — every fresh launch requires the PIN
/// again. See lib/config/admin_config.dart for the important caveat
/// about this being a UI-level gate only, not real backend auth.
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
