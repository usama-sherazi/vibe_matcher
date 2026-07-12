import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/admin_config.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

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
    final controller = TextEditingController();
    String? error;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Admin access'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter the admin PIN to view and manage all profiles.'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: 'PIN', errorText: error),
                onSubmitted: (_) {
                  if (controller.text == kAdminPin) {
                    Navigator.pop(ctx, true);
                  } else {
                    setState(() => error = 'Incorrect PIN');
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (controller.text == kAdminPin) {
                  Navigator.pop(ctx, true);
                } else {
                  setState(() => error = 'Incorrect PIN');
                }
              },
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result ?? false;
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
          ? 'This is your own profile. Deleting it will sign you out of this device permanently. This can\'t be undone.'
          : 'This permanently removes this profile and its matches. This can\'t be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || profile.id == null) return;

    setState(() => _deletingIds.add(profile.id!));
    try {
      await ref.read(apiServiceProvider).deleteProfile(profile.id!);
      if (isSelf) {
        await ref.read(localStoreProvider).clearProfileId();
        ref.read(profileIdProvider.notifier).state = null;
        ref.read(profileDraftProvider.notifier).reset();
      }
      ref.invalidate(allProfilesProvider);
      if (isSelf) ref.invalidate(myProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${profile.name.isEmpty ? "Profile" : profile.name} deleted')),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppColors.ink.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Text('${profile.name}, ${profile.age}', style: Theme.of(ctx).textTheme.headlineSmall),
            if (profile.city.isNotEmpty) Text(profile.city, style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 4),
            SelectableText('ID: ${profile.id ?? "—"}', style: Theme.of(ctx).textTheme.bodyMedium),
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
              Wrap(spacing: 8, runSpacing: 8, children: profile.interests.map((i) => Chip(label: Text(i))).toList()),
            ],
            if (profile.values.isNotEmpty) ...[
              const SizedBox(height: 16),
              const SectionLabel('Core values'),
              Wrap(spacing: 8, runSpacing: 8, children: profile.values.map((v) => Chip(label: Text(v))).toList()),
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
              color: AppColors.indigo.withOpacity(0.06),
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
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(color: AppColors.ink.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.indigo.withOpacity(0.12),
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
                                                color: AppColors.coral.withOpacity(0.14),
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
