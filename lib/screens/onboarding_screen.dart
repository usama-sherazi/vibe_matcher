import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'home_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;
  bool _saving = false;
  String? _error;

  static const _stepCount = 4;
  static const _stepTitles = ['The basics', 'Your personality', 'Your preferences', 'Review'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _basicsValid {
    final draft = ref.read(profileDraftProvider);
    return draft.name.trim().isNotEmpty && draft.city.trim().isNotEmpty && draft.age >= 13;
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(step, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  void _next() {
    if (_step == 0 && !_basicsValid) {
      setState(() => _error = 'Add your name, age, and city to continue.');
      return;
    }
    setState(() => _error = null);
    if (_step < _stepCount - 1) {
      _goTo(_step + 1);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step == 0) return;
    _goTo(_step - 1);
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final draft = ref.read(profileDraftProvider);
    final api = ref.read(apiServiceProvider);
    final store = ref.read(localStoreProvider);
    try {
      final saved = await api.saveProfile(draft);
      if (saved.id == null) throw ApiException(500, 'Profile saved but no id was returned.');
      await store.saveProfileId(saved.id!);
      ref.read(profileIdProvider.notifier).state = saved.id;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'Could not save your profile. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(step: _step, stepCount: _stepCount, title: _stepTitles[_step], onBack: _step > 0 ? _back : null),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE9E7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppColors.coralDeep)),
                ),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _BasicsStep(),
                  _PersonalityStep(),
                  _PreferencesStep(),
                  _ReviewStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _next,
                  child: _saving
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                        )
                      : Text(_step == _stepCount - 1 ? 'Create my profile' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.step, required this.stepCount, required this.title, this.onBack});
  final int step;
  final int stepCount;
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: onBack == null ? Colors.transparent : AppColors.ink),
              ),
              Expanded(
                child: Row(
                  children: List.generate(stepCount, (i) {
                    final active = i <= step;
                    return Expanded(
                      child: Container(
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: active ? AppColors.coral : AppColors.ink.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Step 1

class _BasicsStep extends ConsumerStatefulWidget {
  const _BasicsStep();

  @override
  ConsumerState<_BasicsStep> createState() => _BasicsStepState();
}

class _BasicsStepState extends ConsumerState<_BasicsStep> {
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _bio;
  late final TextEditingController _goals;
  late final TextEditingController _interests;
  late int _age;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(profileDraftProvider);
    _name = TextEditingController(text: draft.name);
    _city = TextEditingController(text: draft.city);
    _bio = TextEditingController(text: draft.bio);
    _goals = TextEditingController(text: draft.goals);
    _interests = TextEditingController(text: draft.interests.join(', '));
    _age = draft.age;
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _bio.dispose();
    _goals.dispose();
    _interests.dispose();
    super.dispose();
  }

  void _sync() {
    ref.read(profileDraftProvider.notifier).updateBasics(
          name: _name.text,
          city: _city.text,
          bio: _bio.text,
          goals: _goals.text,
          age: _age,
          interests: _interests.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        const SectionLabel('About you'),
        TextField(
          controller: _name,
          onChanged: (_) => _sync(),
          decoration: const InputDecoration(labelText: 'Your name'),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _city,
                onChanged: (_) => _sync(),
                decoration: const InputDecoration(labelText: 'City'),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 120,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.ink.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text('Age', style: Theme.of(context).textTheme.bodyMedium)),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: () => setState(() { if (_age > 13) _age--; _sync(); }),
                    ),
                    Text('$_age', style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () => setState(() { _age++; _sync(); }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionLabel('A little bio'),
        TextField(
          controller: _bio,
          onChanged: (_) => _sync(),
          maxLines: 3,
          maxLength: 220,
          decoration: const InputDecoration(hintText: '1-3 sentences about you'),
        ),
        const SizedBox(height: 6),
        const SectionLabel('Interests'),
        TextField(
          controller: _interests,
          onChanged: (_) => _sync(),
          decoration: const InputDecoration(hintText: 'reading, travel, art (comma separated)'),
        ),
        const SizedBox(height: 6),
        const SectionLabel('What are you looking for?'),
        TextField(
          controller: _goals,
          onChanged: (_) => _sync(),
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'e.g. close friends who share my interests'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Step 2

class _PersonalityStep extends ConsumerStatefulWidget {
  const _PersonalityStep();

  @override
  ConsumerState<_PersonalityStep> createState() => _PersonalityStepState();
}

class _PersonalityStepState extends ConsumerState<_PersonalityStep> {
  PersonalitySnapshot? _snapshot;
  bool _loadingSnapshot = false;

  Future<void> _refreshSnapshot() async {
    setState(() => _loadingSnapshot = true);
    try {
      final traits = ref.read(profileDraftProvider).traits;
      final snapshot = await ref.read(apiServiceProvider).assess(traits);
      if (mounted) setState(() => _snapshot = snapshot);
    } catch (_) {
      // Silently skip — this is a nice-to-have preview, not required to proceed.
    } finally {
      if (mounted) setState(() => _loadingSnapshot = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(profileDraftProvider);
    final values = kTraitKeys.map((k) => draft.traits[k] ?? 50).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        Text(
          'Slide to reflect how you naturally are — there are no right answers.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              TraitRadarChart(values: values, labels: kTraitKeys.map((k) => kTraitLabels[k]!.split(' ').first).toList()),
              if (_loadingSnapshot)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_snapshot != null && _snapshot!.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _snapshot!.notes.first,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final key in kTraitKeys)
          TraitSlider(
            label: kTraitLabels[key]!,
            value: draft.traits[key] ?? 50,
            onChanged: (v) => ref.read(profileDraftProvider.notifier).updateTrait(key, v),
          ),
        Center(
          child: TextButton.icon(
            onPressed: _refreshSnapshot,
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Preview my personality snapshot'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Step 3

class _PreferencesStep extends ConsumerWidget {
  const _PreferencesStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(profileDraftProvider);
    final notifier = ref.read(profileDraftProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        const SectionLabel('What matters to you'),
        ChipMultiSelect(
          options: kValueOptions,
          selected: draft.values,
          onToggle: notifier.toggleValue,
        ),
        const SizedBox(height: 22),
        const SectionLabel('More about you'),
        for (final key in kExtraSliderKeys)
          TraitSlider(
            label: kExtraSliderLabels[key]!,
            value: (draft.extras[key] as int?) ?? 50,
            onChanged: (v) => notifier.updateExtra(key, v),
          ),
        const SizedBox(height: 10),
        SelectField(
          label: 'Availability',
          value: draft.extras['availability']?.toString() ?? kAvailabilityOptions.first,
          options: kAvailabilityOptions,
          onChanged: (v) => notifier.updateExtra('availability', v),
        ),
        const SizedBox(height: 12),
        SelectField(
          label: 'Communication style',
          value: draft.extras['communication_style']?.toString() ?? kCommunicationStyleOptions.first,
          options: kCommunicationStyleOptions,
          onChanged: (v) => notifier.updateExtra('communication_style', v),
        ),
        const SizedBox(height: 12),
        SelectField(
          label: 'Conflict style',
          value: draft.extras['conflict_style']?.toString() ?? kConflictStyleOptions.first,
          options: kConflictStyleOptions,
          onChanged: (v) => notifier.updateExtra('conflict_style', v),
        ),
        const SizedBox(height: 12),
        SelectField(
          label: 'Attachment style',
          value: draft.extras['attachment_style']?.toString() ?? kAttachmentStyleOptions.first,
          options: kAttachmentStyleOptions,
          onChanged: (v) => notifier.updateExtra('attachment_style', v),
        ),
        const SizedBox(height: 12),
        SelectField(
          label: 'Support style',
          value: draft.extras['support_style']?.toString() ?? kSupportStyleOptions.first,
          options: kSupportStyleOptions,
          onChanged: (v) => notifier.updateExtra('support_style', v),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Step 4

class _ReviewStep extends ConsumerWidget {
  const _ReviewStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(profileDraftProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: AppColors.gradientWarm, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${draft.name.isEmpty ? "Your name" : draft.name}, ${draft.age}',
                  style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text(draft.city.isEmpty ? 'Your city' : draft.city,
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.9))),
              if (draft.bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(draft.bio, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (draft.interests.isNotEmpty) ...[
          const SectionLabel('Interests'),
          Wrap(spacing: 8, runSpacing: 8, children: draft.interests.map((i) => Chip(label: Text(i))).toList()),
          const SizedBox(height: 16),
        ],
        if (draft.values.isNotEmpty) ...[
          const SectionLabel('Core values'),
          Wrap(spacing: 8, runSpacing: 8, children: draft.values.map((v) => Chip(label: Text(v))).toList()),
          const SizedBox(height: 16),
        ],
        const SectionLabel('Personality snapshot'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: TraitRadarChart(
            values: kTraitKeys.map((k) => draft.traits[k] ?? 50).toList(),
            labels: kTraitKeys.map((k) => kTraitLabels[k]!.split(' ').first).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You can edit any of this later from your profile.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
