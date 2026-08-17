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
    return VcCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            decoration: const BoxDecoration(
              gradient: AppColors.gradientWarm,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VcAvatar(name: match.displayName, radius: 30, imageBytes: match.photoBytes),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${match.displayName}, ${match.age}', style: theme.textTheme.titleLarge),
                          if (match.city.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.place_outlined, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                                const SizedBox(width: 4),
                                Flexible(child: Text(match.city, style: theme.textTheme.bodyMedium)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    ScoreBadge(score: match.score, size: 62),
                  ],
                ),
                if (match.summary.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(match.summary, style: theme.textTheme.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
                if (match.strengths.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: match.strengths.take(3).map((s) => VcPill(s)).toList(),
                  ),
                ],
                if (match.suggestedOpener.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.format_quote_rounded, size: 18, color: AppColors.coral),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            match.suggestedOpener,
                            style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'View ${match.displayName}',
                      style: theme.textTheme.labelLarge?.copyWith(color: AppColors.indigo),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.indigo),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
