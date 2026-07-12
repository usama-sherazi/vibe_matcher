import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, required this.onTap});

  final MatchResult match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppColors.ink.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.indigo.withOpacity(0.12),
                  child: Text(
                    match.name.isNotEmpty ? match.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w700, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${match.name}, ${match.age}', style: theme.textTheme.titleLarge),
                      if (match.city.isNotEmpty)
                        Text(match.city, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                ScoreBadge(score: match.score),
              ],
            ),
            if (match.summary.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(match.summary, style: theme.textTheme.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            if (match.suggestedOpener.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.coral),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.suggestedOpener,
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.ink.withOpacity(0.8)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
