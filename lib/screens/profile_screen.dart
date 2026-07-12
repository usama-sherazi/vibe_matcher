import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'admin_screen.dart';
import 'onboarding_screen.dart';
import 'splash_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Delete your profile?',
      message: 'This removes your profile and matches permanently from the server. This can\'t be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await ref.read(apiServiceProvider).deleteProfile(id);
      await ref.read(localStoreProvider).clearProfileId();
      ref.read(profileIdProvider.notifier).state = null;
      ref.read(profileDraftProvider.notifier).reset();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete profile: $e')));
      }
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Log out?',
      message: 'Vibe Connect doesn\'t use passwords — signing out on this device is the only way in. '
          'Your profile and matches stay saved on the server, but you\'ll need to create a new profile '
          'to use the app again on this device.',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (!confirmed) return;

    await ref.read(localStoreProvider).clearProfileId();
    ref.read(profileIdProvider.notifier).state = null;
    ref.read(profileDraftProvider.notifier).reset();
    ref.read(adminUnlockedProvider.notifier).state = false;

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load your profile',
          message: err.toString(),
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(myProfileProvider),
        ),
        data: (profile) {
          if (profile == null) {
            return const EmptyState(icon: Icons.person_off_outlined, title: 'No profile found.');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myProfileProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(gradient: AppColors.gradientWarm, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${profile.name}, ${profile.age}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
                      const SizedBox(height: 4),
                      if (profile.city.isNotEmpty)
                        Text(profile.city, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.9))),
                      if (profile.bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(profile.bio, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (profile.interests.isNotEmpty) ...[
                  const SectionLabel('Interests'),
                  Wrap(spacing: 8, runSpacing: 8, children: profile.interests.map((i) => Chip(label: Text(i))).toList()),
                  const SizedBox(height: 16),
                ],
                if (profile.values.isNotEmpty) ...[
                  const SectionLabel('Core values'),
                  Wrap(spacing: 8, runSpacing: 8, children: profile.values.map((v) => Chip(label: Text(v))).toList()),
                  const SizedBox(height: 16),
                ],
                const SectionLabel('Personality snapshot'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: TraitRadarChart(
                    values: kTraitKeys.map((k) => profile.traits[k] ?? 50).toList(),
                    labels: kTraitKeys.map((k) => kTraitLabels[k]!.split(' ').first).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(profileDraftProvider.notifier).reset(profile);
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit profile'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => AdminAccess.open(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.indigo,
                    side: const BorderSide(color: AppColors.indigo),
                  ),
                  icon: const Icon(Icons.shield_rounded),
                  label: const Text('Admin'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _logout(context, ref),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out'),
                ),
                const SizedBox(height: 12),
                if (profile.id != null)
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: profile.id!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile ID copied')),
                      );
                    },
                    icon: const Icon(Icons.badge_outlined, size: 18, color: AppColors.inkSoft),
                    label: Text('ID: ${profile.id}', style: const TextStyle(color: AppColors.inkSoft)),
                  ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, ref, profile.id!),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coralDeep),
                  label: const Text('Delete my profile', style: TextStyle(color: AppColors.coralDeep)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
