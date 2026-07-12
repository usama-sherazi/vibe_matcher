import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.myId, required this.candidateId});

  final String myId;
  final String candidateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Match report')),
      body: FutureBuilder<MatchDetail>(
        future: api.compare(myId, candidateId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Couldn\'t load this match: ${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }
          final detail = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  ScoreBadge(score: detail.score, size: 72),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${detail.name}, ${detail.age}', style: Theme.of(context).textTheme.headlineSmall),
                        if (detail.city.isNotEmpty) Text(detail.city, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              if (detail.summary.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: Text(detail.summary, style: Theme.of(context).textTheme.bodyLarge),
                ),
              ],
              if (detail.strengths.isNotEmpty) ...[
                const SizedBox(height: 20),
                const SectionLabel('Strengths'),
                ...detail.strengths.map((s) => _BulletRow(text: s, color: AppColors.success, icon: Icons.check_circle_rounded)),
              ],
              if (detail.watchouts.isNotEmpty) ...[
                const SizedBox(height: 20),
                const SectionLabel('Worth knowing'),
                ...detail.watchouts.map((s) => _BulletRow(text: s, color: AppColors.warning, icon: Icons.info_rounded)),
              ],
              if (detail.breakdownSections.isNotEmpty) ...[
                const SizedBox(height: 20),
                const SectionLabel('Compatibility breakdown'),
                ...detail.breakdownSections.entries.map((entry) => _BreakdownCard(title: entry.key, data: entry.value)),
              ],
              if (detail.suggestedOpener.isNotEmpty) ...[
                const SizedBox(height: 20),
                const SectionLabel('Suggested opener'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(gradient: AppColors.gradientWarm, borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detail.suggestedOpener, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: Colors.white),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: detail.suggestedOpener));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opener copied')),
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
          );
        },
      ),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_prettyTitle(title), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...data.entries.map((e) {
            final value = e.value;
            final isNumeric = value is num;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(_prettyTitle(e.key), style: Theme.of(context).textTheme.bodyMedium)),
                  if (isNumeric)
                    SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (value.toDouble() / 100).clamp(0, 1),
                          minHeight: 8,
                          backgroundColor: AppColors.ink.withOpacity(0.08),
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
    );
  }
}
