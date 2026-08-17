import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'discover_screen.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  bool _handlingMissingProfile = false;

  static const _screens = [DiscoverScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    ref.listen(myProfileProvider, (previous, next) {
      next.whenOrNull(
        error: (err, _) async {
          final isMissing = err is ApiException && err.statusCode == 404;
          if (!isMissing || _handlingMissingProfile) return;
          _handlingMissingProfile = true;
          final user = ref.read(currentUserProvider);
          if (user != null) {
            final updated = await ref.read(authServiceProvider).linkProfile(user.id, null);
            await applySession(ref, updated);
          } else {
            ref.read(profileIdProvider.notifier).state = null;
          }
          ref.read(profileDraftProvider.notifier).reset();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your matching profile is gone. Let\'s set it up again.')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()),
            (route) => false,
          );
        },
      );
    });

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded, color: AppColors.coral),
              label: 'Discover',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.coral),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
