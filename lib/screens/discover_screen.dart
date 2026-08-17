import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/match_card.dart';
import '../widgets/shared_widgets.dart';
import 'match_detail_screen.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  Timer? _coldStartTimer;
  bool _showColdStart = false;

  @override
  void initState() {
    super.initState();
    _coldStartTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && ref.read(matchesProvider).isLoading) {
        setState(() => _showColdStart = true);
      }
    });
  }

  @override
  void dispose() {
    _coldStartTimer?.cancel();
    super.dispose();
  }

  void _onMatchesChange(AsyncValue<List<MatchResult>> next) {
    next.when(
      data: (_) {
        _coldStartTimer?.cancel();
        _coldStartTimer = null;
        if (_showColdStart) setState(() => _showColdStart = false);
      },
      error: (_, __) {
        _coldStartTimer?.cancel();
        _coldStartTimer = null;
        if (_showColdStart) setState(() => _showColdStart = false);
      },
      loading: () {
        _coldStartTimer ??= Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showColdStart = true);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchesProvider);
    final myId = ref.watch(profileIdProvider);
    final profile = ref.watch(myProfileProvider).valueOrNull;
    ref.listen(matchesProvider, (_, next) => _onMatchesChange(next));
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile == null ? 'Discover' : 'Hey ${profile.name.split(' ').first}',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'People who actually get your vibe',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => ref.invalidate(matchesProvider),
                    tooltip: 'Refresh matches',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.coral.withValues(alpha: 0.12),
                      foregroundColor: AppColors.coral,
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            if (_showColdStart && matchesAsync.isLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.indigo.withValues(alpha: 0.12),
                        AppColors.coral.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Waking up the server — first load can take a minute.'),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.coral,
                onRefresh: () async => ref.invalidate(matchesProvider),
                child: matchesAsync.when(
                  skipLoadingOnReload: true,
                  data: (matches) {
                    if (matches.isEmpty) {
                      return const EmptyState(
                        icon: Icons.favorite_outline_rounded,
                        title: 'No matches yet',
                        message: 'Pull down to refresh once the matching server is awake.',
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: matches.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Text(
                            '${matches.length} ${matches.length == 1 ? 'person' : 'people'} ranked for you',
                            style: theme.textTheme.labelLarge?.copyWith(color: AppColors.indigo),
                          );
                        }
                        final match = matches[i - 1];
                        return MatchCard(
                          match: match,
                          onTap: () {
                            if (myId == null) return;
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => MatchDetailScreen(myId: myId, candidateId: match.matchId),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => VcErrorState(
                    title: 'Couldn\'t load matches',
                    message: err.toString(),
                    onRetry: () => ref.invalidate(matchesProvider),
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
