import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../widgets/match_card.dart';
import '../widgets/shared_widgets.dart';
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
            tooltip: 'Refresh matches',
            onPressed: () => ref.invalidate(matchesProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(matchesProvider),
        child: matchesAsync.when(
          data: (matches) {
            if (matches.isEmpty) {
              return const EmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No matches yet',
                message: 'Check back soon, or pull down to refresh.',
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
          error: (err, _) => EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Couldn\'t load matches',
            message: err.toString(),
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(matchesProvider),
          ),
        ),
      ),
    );
  }
}
