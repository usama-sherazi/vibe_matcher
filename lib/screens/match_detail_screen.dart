import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.myId, required this.candidateId});

  final String myId;
  final String candidateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(matchDetailProvider((myId: myId, candidateId: candidateId)));
    final theme = Theme.of(context);

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Match report')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Match report')),
        body: VcErrorState(
          title: 'Couldn\'t load this match',
          message: err.toString(),
          onRetry: () => ref.invalidate(matchDetailProvider((myId: myId, candidateId: candidateId))),
        ),
      ),
      data: (detail) {
        final name = detail.displayName;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.indigoDeep,
                foregroundColor: Colors.white,
                title: Text(name),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (detail.photoBytes != null)
                        Image.memory(detail.photoBytes!, fit: BoxFit.cover)
                      else
                        const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.gradientWarm)),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xCC221D2E)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            VcAvatar(name: name, radius: 36, imageBytes: detail.photoBytes),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$name, ${detail.age}', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
                                  if (detail.city.isNotEmpty)
                                    Text(detail.city, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70)),
                                ],
                              ),
                            ),
                            ScoreBadge(score: detail.score, size: 78),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                sliver: SliverList.list(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'Match report',
                          style: theme.textTheme.labelLarge?.copyWith(color: AppColors.indigo),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your match with $name',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 14),
                    VcCard(
                      child: Row(
                        children: [
                          ScoreBadge(score: detail.score, size: 86),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'You and $name line up at ${detail.score.round()}% compatibility.',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (detail.summary.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      VcCard(child: Text(detail.summary, style: theme.textTheme.bodyLarge)),
                    ],
                    if (detail.strengths.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const SectionLabel('Strengths'),
                      ...detail.strengths.map(
                        (s) => _BulletRow(text: s, color: AppColors.success, icon: Icons.check_circle_rounded),
                      ),
                    ],
                    if (detail.watchouts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const SectionLabel('Worth knowing'),
                      ...detail.watchouts.map(
                        (s) => _BulletRow(text: s, color: AppColors.warning, icon: Icons.info_rounded),
                      ),
                    ],
                    if (detail.breakdownSections.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const SectionLabel('Compatibility breakdown'),
                      ...detail.breakdownSections.entries.map(
                        (entry) => _BreakdownCard(title: entry.key, data: entry.value),
                      ),
                    ],
                    if (detail.suggestedOpener.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SectionLabel('Say hi to $name'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(gradient: AppColors.gradientWarm, borderRadius: BorderRadius.circular(22)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.format_quote_rounded, color: Colors.white, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              detail.suggestedOpener,
                              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white, height: 1.45),
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                                ),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: detail.suggestedOpener));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Opener for $name copied')),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                                label: const Text('Copy'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text, required this.color, required this.icon});
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: VcCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.title, required this.data});
  final String title;
  final Map<String, dynamic> data;

  String _prettyTitle(String key) => key.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: VcCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_prettyTitle(title), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...data.entries.map((e) {
              final value = e.value;
              final isNumeric = value is num;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(child: Text(_prettyTitle(e.key), style: Theme.of(context).textTheme.bodyMedium)),
                    if (isNumeric)
                      SizedBox(
                        width: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (value.toDouble() / 100).clamp(0, 1),
                            minHeight: 8,
                            backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                            color: AppColors.indigo,
                          ),
                        ),
                      )
                    else
                      Text(value.toString(), style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
