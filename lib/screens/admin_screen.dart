import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/admin_config.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'onboarding_screen.dart';

/// Entry point for the admin panel. Always route through this helper
/// rather than pushing [AdminScreen] directly — it enforces the PIN
/// gate first (see admin_config.dart for what that does and doesn't
/// protect against).
class AdminAccess {
  AdminAccess._();

  static Future<void> open(BuildContext context, WidgetRef ref) async {
    if (!ref.read(adminUnlockedProvider)) {
      final unlocked = await _promptPin(context);
      if (!unlocked) return;
      ref.read(adminUnlockedProvider.notifier).state = true;
    }
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminScreen()));
  }

  static Future<bool> _promptPin(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _AdminPinDialog(),
    );
    return result ?? false;
  }
}

/// A dedicated StatefulWidget for the PIN prompt — not a StatefulBuilder
/// with a manually-disposed controller. Flutter needs to own this
/// controller's lifecycle itself (via State.dispose) so it doesn't get
/// torn down while the dialog's closing animation is still running,
/// which is what caused the "TextEditingController used after being
/// disposed" crash.
class _AdminPinDialog extends StatefulWidget {
  const _AdminPinDialog();

  @override
  State<_AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<_AdminPinDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text == kAdminPin) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = 'Incorrect PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Admin access'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter the admin PIN to view and manage all profiles.'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: 'PIN', errorText: _error),
            onChanged: _error == null ? null : (_) => setState(() => _error = null),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Unlock')),
      ],
    );
  }
}

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  final Set<String> _deletingIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Profile> _filtered(List<Profile> profiles) {
    if (_query.trim().isEmpty) return profiles;
    final q = _query.trim().toLowerCase();
    return profiles.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.city.toLowerCase().contains(q) ||
          (p.id ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _deleteProfile(Profile profile, {required String? myId}) async {
    final isSelf = profile.id != null && profile.id == myId;
    final confirmed = await confirmDialog(
      context,
      title: 'Delete ${profile.name.isEmpty ? "this profile" : profile.name}?',
      message: isSelf
          ? 'This is your own matching profile. You\'ll stay logged in and can create a new one. This can\'t be undone.'
          : 'This permanently removes this profile and its matches. This can\'t be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || profile.id == null) return;

    setState(() => _deletingIds.add(profile.id!));
    try {
      await ref.read(apiServiceProvider).deleteProfile(profile.id!);
      if (isSelf) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          final updated = await ref.read(authServiceProvider).linkProfile(user.id, null);
          await applySession(ref, updated);
        } else {
          await ref.read(localStoreProvider).clearProfileId();
          ref.read(profileIdProvider.notifier).state = null;
        }
        ref.read(profileDraftProvider.notifier).reset();
      }
      ref.invalidate(allProfilesProvider);
      if (isSelf) ref.invalidate(myProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${profile.name.isEmpty ? "Profile" : profile.name} deleted')),
      );
      if (isSelf) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Could not delete this profile.')),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingIds.remove(profile.id));
    }
  }

  void _showDetail(Profile profile) {
    showVcSheet<void>(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.only(top: 40),
          child: VcSheetScaffold(
            title: '${profile.name}, ${profile.age}',
            subtitle: profile.city.isEmpty ? null : profile.city,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.72),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Center(child: VcAvatar(name: profile.name, radius: 36, imageBytes: profile.photoBytes)),
                  const SizedBox(height: 12),
                  SelectableText(
                    'ID: ${profile.id ?? "—"}',
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  if (profile.bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const SectionLabel('Bio'),
                    Text(profile.bio),
                  ],
                  if (profile.goals.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const SectionLabel('Looking for'),
                    Text(profile.goals),
                  ],
                  if (profile.interests.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const SectionLabel('Interests'),
                    Wrap(spacing: 8, runSpacing: 8, children: profile.interests.map((i) => VcPill(i)).toList()),
                  ],
                  if (profile.values.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const SectionLabel('Core values'),
                    Wrap(spacing: 8, runSpacing: 8, children: profile.values.map((v) => VcPill(v, filled: true)).toList()),
                  ],
                  const SizedBox(height: 16),
                  const SectionLabel('Personality'),
                  TraitRadarChart(
                    values: kTraitKeys.map((k) => profile.traits[k] ?? 50).toList(),
                    labels: kTraitKeys.map((k) => kTraitLabels[k]!.split(' ').first).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(allProfilesProvider);
    final myId = ref.watch(profileIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(allProfilesProvider),
          ),
        ],
      ),
      body: KeyboardDismissible(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.indigo.withValues(alpha: 0.06),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, size: 16, color: AppColors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can view and permanently delete any profile here.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.indigo),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: SearchField(
                controller: _searchController,
                hintText: 'Search by name, city, or ID',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(allProfilesProvider),
                child: profilesAsync.when(
                  data: (profiles) {
                    final filtered = _filtered(profiles);
                    if (profiles.isEmpty) {
                      return const EmptyState(
                        icon: Icons.people_outline_rounded,
                        title: 'No profiles yet',
                        message: 'Profiles created by users will show up here.',
                      );
                    }
                    if (filtered.isEmpty) {
                      return EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matches for "$_query"',
                        actionLabel: 'Clear search',
                        onAction: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final profile = filtered[i];
                        final isSelf = profile.id != null && profile.id == myId;
                        final isDeleting = _deletingIds.contains(profile.id);
                        return VcCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
                                child: Text(
                                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _showDetail(profile),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '${profile.name.isEmpty ? "Unnamed" : profile.name}, ${profile.age}',
                                              style: Theme.of(context).textTheme.titleMedium,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isSelf) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.coral.withValues(alpha: 0.14),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text('You', style: TextStyle(fontSize: 11, color: AppColors.coralDeep, fontWeight: FontWeight.w600)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (profile.city.isNotEmpty)
                                        Text(profile.city, style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                              ),
                              isDeleting
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2),
                              )
                                  : IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coralDeep),
                                tooltip: 'Delete profile',
                                onPressed: () => _deleteProfile(profile, myId: myId),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Couldn\'t load profiles',
                    message: err.toString(),
                    actionLabel: 'Try again',
                    onAction: () => ref.invalidate(allProfilesProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
