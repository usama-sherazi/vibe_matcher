import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum VcButtonVariant { filled, outlined, text }

class VcButton extends StatelessWidget {
  const VcButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.expanded = true,
    this.variant = VcButtonVariant.filled,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;
  final VcButtonVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final callback = loading ? null : onPressed;
    late final Widget button;
    switch (variant) {
      case VcButtonVariant.filled:
        button = ElevatedButton(onPressed: callback, child: child);
      case VcButtonVariant.outlined:
        button = OutlinedButton(onPressed: callback, child: child);
      case VcButtonVariant.text:
        button = TextButton(onPressed: callback, child: child);
    }

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class VcTextField extends StatelessWidget {
  const VcTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.enabled = true,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                tooltip: obscureText ? 'Show password' : 'Hide password',
                onPressed: onToggleObscure,
                icon: Icon(
                  obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
              ),
      ),
    );
  }
}

class VcCard extends StatelessWidget {
  const VcCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = scheme.onSurface;
    final card = Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.24 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: card,
      ),
    );
  }
}

class VcAvatar extends StatelessWidget {
  const VcAvatar({
    super.key,
    required this.name,
    this.radius = 28,
    this.imageBytes,
  });

  final String name;
  final double radius;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageBytes == null ? AppColors.gradientWarm : null,
        image: imageBytes == null
            ? null
            : DecorationImage(image: MemoryImage(imageBytes!), fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: imageBytes == null
          ? Text(
              letter,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.85,
              ),
            )
          : null,
    );
  }
}

class VcPill extends StatelessWidget {
  const VcPill(this.label, {super.key, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: filled ? AppColors.indigo : AppColors.indigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: filled ? Colors.white : AppColors.indigo,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class VcActionTile extends StatelessWidget {
  const VcActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.tone = VcActionTone.neutral,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final VcActionTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      VcActionTone.neutral => Theme.of(context).colorScheme.onSurface,
      VcActionTone.accent => AppColors.indigo,
      VcActionTone.danger => AppColors.coralDeep,
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color)),
                    if (subtitle != null)
                      Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.45)),
            ],
          ),
        ),
      ),
    );
  }
}

enum VcActionTone { neutral, accent, danger }

Future<T?> showVcSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.46),
    builder: builder,
  );
}

class VcSheetScaffold extends StatelessWidget {
  const VcSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
            child: Column(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class VcErrorBanner extends StatelessWidget {
  const VcErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.coralDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppColors.coralDeep)),
          ),
        ],
      ),
    );
  }
}

class VcEmptyState extends StatelessWidget {
  const VcEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 56),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.coral.withValues(alpha: 0.18),
                AppColors.indigo.withValues(alpha: 0.18),
              ],
            ),
          ),
          child: Icon(icon, size: 40, color: iconColor ?? AppColors.indigo),
        ),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(message!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ),
        ],
      ],
    );
  }
}

class VcErrorState extends StatelessWidget {
  const VcErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return VcEmptyState(
      icon: Icons.cloud_off_rounded,
      title: title,
      message: message,
      actionLabel: onRetry == null ? null : 'Try again',
      onAction: onRetry,
    );
  }
}

/// Back-compat alias used across existing screens.
typedef EmptyState = VcEmptyState;

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
              Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.indigo.withValues(alpha: 0.12),
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
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
            color: isSelected ? Colors.white : onSurface,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}

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
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          FocusManager.instance.primaryFocus?.unfocus();
          final choice = await showVcSheet<String>(
            context: context,
            builder: (ctx) => VcSheetScaffold(
              title: label,
              subtitle: 'Pick the option that feels most like you',
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.55),
                child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                itemCount: options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final option = options[i];
                  final selected = option == value;
                  return Material(
                    color: selected ? AppColors.indigo.withValues(alpha: 0.1) : scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(ctx, option),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? AppColors.indigo : scheme.onSurface.withValues(alpha: 0.08),
                            width: selected ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: selected ? AppColors.indigo : null,
                                ),
                              ),
                            ),
                            Icon(
                              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                              color: selected ? AppColors.coral : scheme.onSurface.withValues(alpha: 0.25),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              ),
            ),
          );
          if (choice != null) onChanged(choice);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: AppColors.indigo, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(value, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.expand_more_rounded, color: AppColors.coral),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score, this.size = 56, this.caption});

  final double score;
  final double size;
  final String? caption;

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.gold;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? score : 0, end: score),
      duration: Duration(milliseconds: reduce ? 0 : 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _ScoreRingPainter(progress: (value / 100).clamp(0, 1), color: _color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.round().toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.32,
                      color: _color,
                      height: 1,
                    ),
                  ),
                  if (caption != null || size >= 64)
                    Text(
                      caption ?? 'match',
                      style: TextStyle(
                        fontSize: size * 0.14,
                        fontWeight: FontWeight.w600,
                        color: _color.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  _ScoreRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.width * 0.09;
    final radius = (size.width - stroke) / 2;
    final track = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [color, color.withValues(alpha: 0.65), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class TraitRadarChart extends StatelessWidget {
  const TraitRadarChart({super.key, required this.values, required this.labels});

  final List<int> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return AspectRatio(
      aspectRatio: 1,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduce ? 1 : 0.15, end: 1),
        duration: Duration(milliseconds: reduce ? 0 : 900),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          return CustomPaint(
            painter: _RadarPainter(
              values: values.map((v) => v * t).toList(),
              labels: labels,
              gridColor: onSurface.withValues(alpha: 0.08),
              axisColor: onSurface.withValues(alpha: 0.07),
              labelColor: onSurface.withValues(alpha: 0.62),
            ),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.values,
    required this.labels,
    required this.gridColor,
    required this.axisColor,
    required this.labelColor,
  });

  final List<double> values;
  final List<String> labels;
  final Color gridColor;
  final Color axisColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 36;
    final sides = values.length;
    if (sides < 3) return;
    final angleStep = (2 * math.pi) / sides;

    Offset pointFor(int i, double r) {
      final angle = -math.pi / 2 + angleStep * i;
      return Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
    }

    Path polygon(double scale) {
      final path = Path();
      for (int i = 0; i <= sides; i++) {
        final p = pointFor(i % sides, radius * scale);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      return path;
    }

    final fillGrid = Paint()..style = PaintingStyle.fill;
    for (int ring = 4; ring >= 1; ring--) {
      fillGrid.color = AppColors.indigo.withValues(alpha: ring.isEven ? 0.045 : 0.02);
      canvas.drawPath(polygon(ring / 4), fillGrid);
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int ring = 1; ring <= 4; ring++) {
      canvas.drawPath(polygon(ring / 4), gridPaint);
    }

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    for (int i = 0; i < sides; i++) {
      canvas.drawLine(center, pointFor(i, radius), axisPaint);
    }

    final dataPath = Path();
    final vertices = <Offset>[];
    for (int i = 0; i < sides; i++) {
      final r = radius * (values[i].clamp(0, 100) / 100);
      final p = pointFor(i, r);
      vertices.add(p);
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }
    dataPath.close();

    final glow = Paint()
      ..color = AppColors.indigo.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, glow);

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomRight,
        colors: [
          AppColors.coral.withValues(alpha: 0.42),
          AppColors.indigo.withValues(alpha: 0.38),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fill);

    final stroke = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.coral, AppColors.indigo],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(dataPath, stroke);

    for (final p in vertices) {
      canvas.drawCircle(p, 7, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..shader = const LinearGradient(colors: [AppColors.coral, AppColors.indigo])
              .createShader(Rect.fromCircle(center: p, radius: 5)),
      );
    }

    for (int i = 0; i < sides; i++) {
      final labelR = radius + 22;
      final point = pointFor(i, labelR);
      final score = values[i].clamp(0, 100).round();
      final tp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: labels[i],
              style: TextStyle(color: labelColor, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
            ),
            TextSpan(
              text: '  $score',
              style: const TextStyle(color: AppColors.indigo, fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 86);
      tp.paint(canvas, point - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.values.toString() != values.toString() ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.labelColor != labelColor;
}

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

class KeyboardDismissible extends StatelessWidget {
  const KeyboardDismissible({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showVcSheet<bool>(
    context: context,
    isScrollControlled: false,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: VcSheetScaffold(
          title: title,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (destructive ? AppColors.coral : AppColors.indigo).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    destructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
                    color: destructive ? AppColors.coralDeep : AppColors.indigo,
                  ),
                ),
                const SizedBox(height: 14),
                Text(message, textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.bodyLarge),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(cancelLabel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: destructive
                            ? ElevatedButton.styleFrom(backgroundColor: AppColors.coralDeep)
                            : null,
                        child: Text(confirmLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return result ?? false;
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}
