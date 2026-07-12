import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/match_card.dart';
import 'match_detail_screen.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);
    final myId = ref.watch(profileIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(matchesProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(matchesProvider),
        child: matchesAsync.when(
          data: (matches) {
            if (matches.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(32),
                children: const [
                  SizedBox(height: 80),
                  Icon(Icons.people_outline_rounded, size: 56, color: AppColors.inkSoft),
                  SizedBox(height: 16),
                  Text(
                    'No matches yet — check back soon, or pull down to refresh.',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: matches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final match = matches[i];
                return MatchCard(
                  match: match,
                  onTap: () {
                    if (myId == null) return;
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => MatchDetailScreen(myId: myId, candidateId: match.matchId),
                    ));
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            padding: const EdgeInsets.all(32),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.inkSoft),
              const SizedBox(height: 16),
              Text('Couldn\'t load matches.\n$err', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton(
                  onPressed: () => ref.invalidate(matchesProvider),
                  child: const Text('Try again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
