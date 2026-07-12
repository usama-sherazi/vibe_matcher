import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A labeled slider with a live value readout — used for Big Five
/// traits and the "extras" dimensions during onboarding.
class TraitSlider extends StatelessWidget {
  const TraitSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.lowHint,
    this.highHint,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String? lowHint;
  final String? highHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.indigo.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$value',
                  style: theme.textTheme.labelLarge?.copyWith(color: AppColors.indigo),
                ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (v) => onChanged(v.round()),
          ),
          if (lowHint != null && highHint != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(lowHint!, style: theme.textTheme.bodyMedium),
                  Text(highHint!, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Multi-select chip group, e.g. for core values.
class ChipMultiSelect extends StatelessWidget {
  const ChipMultiSelect({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onToggle(option),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}

/// Single-select "dropdown as a field" — reads like a form field but
/// opens a clean modal picker instead of the default menu look.
class SelectField extends StatelessWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final choice = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(
                  color: AppColors.ink.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                )),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(label, style: theme.textTheme.titleLarge),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: options.map((o) => ListTile(
                      title: Text(o),
                      trailing: o == value ? const Icon(Icons.check_circle, color: AppColors.coral) : null,
                      onTap: () => Navigator.pop(ctx, o),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
        if (choice != null) onChanged(choice);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text(value, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

/// Circular score badge used on match cards and the detail screen.
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score, this.size = 56});

  final double score;
  final double size;

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.gold;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color.withOpacity(0.14),
        border: Border.all(color: _color, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        score.round().toString(),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
          color: _color,
        ),
      ),
    );
  }
}

/// A small five-axis radar chart for the Big Five snapshot — drawn
/// by hand so onboarding doesn't need a charting dependency.
class TraitRadarChart extends StatelessWidget {
  const TraitRadarChart({super.key, required this.values, required this.labels});

  /// Values 0-100, same order as [labels].
  final List<int> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _RadarPainter(values: values, labels: labels),
        child: Container(),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.values, required this.labels});
  final List<int> values;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 28;
    final sides = values.length;
    final angleStep = (2 * math.pi) / sides;

    final gridPaint = Paint()
      ..color = AppColors.ink.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int ring = 1; ring <= 4; ring++) {
      final path = Path();
      for (int i = 0; i <= sides; i++) {
        final angle = -math.pi / 2 + angleStep * i;
        final r = radius * ring / 4;
        final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    final dataPath = Path();
    final dataPaint = Paint()
      ..color = AppColors.indigo.withOpacity(0.28)
      ..style = PaintingStyle.fill;
    final dataStroke = Paint()
      ..color = AppColors.indigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    for (int i = 0; i < sides; i++) {
      final angle = -math.pi / 2 + angleStep * i;
      final r = radius * (values[i].clamp(0, 100) / 100);
      final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataPaint);
    canvas.drawPath(dataPath, dataStroke);

    final textStyle = TextStyle(color: AppColors.inkSoft, fontSize: 11, fontWeight: FontWeight.w600);
    for (int i = 0; i < sides; i++) {
      final angle = -math.pi / 2 + angleStep * i;
      final labelR = radius + 18;
      final point = Offset(center.dx + labelR * math.cos(angle), center.dy + labelR * math.sin(angle));
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 70);
      tp.paint(canvas, point - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.values.toString() != values.toString();
}

/// Full-bleed warm gradient background used on splash/welcome screens.
class GradientBackdrop extends StatelessWidget {
  const GradientBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradientWarm),
      child: child,
    );
  }
}

/// Simple pill-shaped section header used across steps/screens.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.indigo,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}
