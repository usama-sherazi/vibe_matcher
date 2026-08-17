import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import '../navigation/app_nav.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'admin_screen.dart';
import 'crop_photo_screen.dart';
import 'onboarding_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _savingPhoto = false;

  Future<void> _confirmDelete(String id) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Delete your account?',
      message: 'This removes your matching profile from the server and deletes the local account on this device. This can\'t be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await ref.read(apiServiceProvider).deleteProfile(id);
      await ref.read(photoServiceProvider).deleteLocal(id);
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await ref.read(authServiceProvider).deleteAccount(user.id);
      } else {
        await ref.read(localStoreProvider).clearSession();
      }
      await clearSessionState(ref);
      if (mounted) {
        replaceRoot(context, const WelcomeScreen());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Could not delete profile: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await confirmDialog(
      context,
      title: 'Log out?',
      message: 'You can log back in on this device with the same email and password. Your matching profile stays saved.',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (!confirmed) return;

    await ref.read(authServiceProvider).logout();
    await clearSessionState(ref);
    if (mounted) {
      replaceRoot(context, const WelcomeScreen());
    }
  }

  Future<void> _changePhoto(Profile profile) async {
    if (profile.id == null) return;
    final source = await showVcSheet<ImageSource>(
      context: context,
      isScrollControlled: false,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: VcSheetScaffold(
          title: 'Profile photo',
          subtitle: 'We’ll crop it to a circle and compress it for the app.',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VcActionTile(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose from gallery',
                  tone: VcActionTone.accent,
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                VcActionTile(
                  icon: Icons.photo_camera_outlined,
                  label: 'Take a photo',
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final raw = await ref.read(photoServiceProvider).pickImage(source);
      if (raw == null || !mounted) return;
      final cropped = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => CropPhotoScreen(imageBytes: raw)),
      );
      if (cropped == null || !mounted) return;

      setState(() => _savingPhoto = true);
      final photos = ref.read(photoServiceProvider);
      final compressed = photos.compressToAvatar(cropped);
      await photos.saveLocal(profile.id!, compressed);
      try {
        await ref.read(apiServiceProvider).saveProfile(
              profile.copyWith(extras: photos.extrasWithPhoto(profile.extras, compressed)),
            );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved on this device. Couldn’t sync the photo to the server yet.')),
          );
        }
      }
      ref.invalidate(myProfileProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update your photo. Try another image.')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => SafeArea(
          child: VcErrorState(
            title: 'Could not load your profile',
            message: err.toString(),
            onRetry: () => ref.invalidate(myProfileProvider),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return SafeArea(
              child: EmptyState(
                icon: Icons.person_off_outlined,
                title: 'No profile found',
                message: 'Finish onboarding to start matching.',
                actionLabel: 'Set up profile',
                onAction: () {
                  ref.read(profileDraftProvider.notifier).reset();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()),
                  );
                },
              ),
            );
          }
          final lifestyle = [
            profile.extras['availability']?.toString(),
            profile.extras['communication_style']?.toString(),
            profile.extras['support_style']?.toString(),
          ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();

          return RefreshIndicator(
            color: AppColors.coral,
            onRefresh: () async => ref.invalidate(myProfileProvider),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 20, 20, 72),
                      decoration: const BoxDecoration(
                        gradient: AppColors.gradientWarm,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _savingPhoto ? null : () => _changePhoto(profile),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.72), width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.18),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: _savingPhoto
                                      ? const SizedBox(
                                          width: 112,
                                          height: 112,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.6),
                                        )
                                      : VcAvatar(name: profile.name, radius: 56, imageBytes: profile.photoBytes),
                                ),
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 8),
                                    ],
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.coral),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _savingPhoto ? null : () => _changePhoto(profile),
                            child: Text(
                              profile.photoBytes == null ? 'Add a profile photo' : 'Change photo',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '${profile.name}, ${profile.age}',
                            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          if (profile.city.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.place_outlined, size: 16, color: Colors.white.withValues(alpha: 0.85)),
                                const SizedBox(width: 4),
                                Text(
                                  profile.city,
                                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                                ),
                              ],
                            ),
                          ],
                          if (profile.bio.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              profile.bio,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.95), height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: -36,
                      child: Row(
                        children: [
                          Expanded(child: _StatCard(label: 'Interests', value: '${profile.interests.length}')),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCard(label: 'Values', value: '${profile.values.length}')),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCard(label: 'Age', value: '${profile.age}')),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 52, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (profile.goals.isNotEmpty) ...[
                        const SectionLabel('Looking for'),
                        VcCard(child: Text(profile.goals)),
                        const SizedBox(height: 18),
                      ],
                      if (lifestyle.isNotEmpty) ...[
                        const SectionLabel('How you show up'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: lifestyle.map((item) => VcPill(item, filled: true)).toList(),
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (profile.interests.isNotEmpty) ...[
                        const SectionLabel('Interests'),
                        Wrap(spacing: 8, runSpacing: 8, children: profile.interests.map((i) => VcPill(i)).toList()),
                      ],
                      if (profile.values.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const SectionLabel('Core values'),
                        Wrap(spacing: 8, runSpacing: 8, children: profile.values.map((v) => VcPill(v, filled: true)).toList()),
                      ],
                      const SizedBox(height: 18),
                      const SectionLabel('Personality snapshot'),
                      VcCard(
                        child: Column(
                          children: [
                            TraitRadarChart(
                              values: kTraitKeys.map((k) => profile.traits[k] ?? 50).toList(),
                              labels: kTraitKeys.map((k) => kTraitLabels[k]!.split(' ').first).toList(),
                            ),
                            const SizedBox(height: 8),
                            ...kTraitKeys.map((key) {
                              final value = profile.traits[key] ?? 50;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 92,
                                      child: Text(kTraitLabels[key]!, style: theme.textTheme.labelMedium, overflow: TextOverflow.ellipsis),
                                    ),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: value / 100,
                                          minHeight: 8,
                                          backgroundColor: AppColors.indigo.withValues(alpha: 0.1),
                                          color: AppColors.indigo,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('$value', style: theme.textTheme.labelLarge?.copyWith(color: AppColors.indigo)),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const SectionLabel('Account'),
                      VcCard(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Column(
                          children: [
                            VcActionTile(
                              icon: Icons.edit_rounded,
                              label: 'Edit profile',
                              subtitle: 'Update your bio, traits, and preferences',
                              tone: VcActionTone.accent,
                              onTap: () {
                                ref.read(profileDraftProvider.notifier).reset(profile);
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()),
                                );
                              },
                            ),
                            VcActionTile(
                              icon: Icons.logout_rounded,
                              label: 'Log out',
                              subtitle: user?.email,
                              onTap: _logout,
                            ),
                            if (profile.id != null)
                              VcActionTile(
                                icon: Icons.badge_outlined,
                                label: 'Copy profile ID',
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: profile.id!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Profile ID copied')),
                                  );
                                },
                              ),
                            if (profile.id != null)
                              VcActionTile(
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete my account',
                                subtitle: 'Removes this profile from the server',
                                tone: VcActionTone.danger,
                                onTap: () => _confirmDelete(profile.id!),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _HiddenAdminUnlock(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return VcCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.coral)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _HiddenAdminUnlock extends ConsumerStatefulWidget {
  const _HiddenAdminUnlock();

  @override
  ConsumerState<_HiddenAdminUnlock> createState() => _HiddenAdminUnlockState();
}

class _HiddenAdminUnlockState extends ConsumerState<_HiddenAdminUnlock> {
  int _taps = 0;
  DateTime? _windowStart;

  void _onTap() {
    final now = DateTime.now();
    if (_windowStart == null || now.difference(_windowStart!) > const Duration(seconds: 3)) {
      _windowStart = now;
      _taps = 1;
      return;
    }
    _taps++;
    if (_taps >= 7) {
      _taps = 0;
      _windowStart = null;
      AdminAccess.open(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Vibe Connect 1.0.0',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
