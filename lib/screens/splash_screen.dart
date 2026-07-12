import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'onboarding_screen.dart';
import 'home_shell.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _status = 'Waking up the server…';
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() {
      _failed = false;
      _status = 'Waking up the server…';
    });

    final api = ref.read(apiServiceProvider);
    final store = ref.read(localStoreProvider);

    try {
      // Free-tier cold start can take 30-50s — keep the user informed
      // rather than looking stuck.
      final healthy = await api.ping();
      if (!healthy && mounted) {
        setState(() {
          _status = 'Couldn\'t reach the server. Check your connection.';
          _failed = true;
        });
        return;
      }

      final savedId = await store.readProfileId();
      if (!mounted) return;

      if (savedId != null) {
        ref.read(profileIdProvider.notifier).state = savedId;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = 'Something went wrong starting up.';
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 24),
              Text(
                'Vibe Connect',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Find people who actually get you',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.85)),
              ),
              const SizedBox(height: 40),
              if (!_failed)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.6),
                )
              else
                const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 28),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.85)),
                ),
              ),
              if (_failed) ...[
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: _bootstrap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
