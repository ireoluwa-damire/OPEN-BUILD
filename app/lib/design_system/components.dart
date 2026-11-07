import 'package:flutter/material.dart';

import '../effects/effects_service.dart';

import '../theme.dart';
import 'motion.dart';

/// DC §7.1 button variants.
enum TactileVariant { primary, secondary, danger, warning, outline, text }

/// The raised, crisp-edged button (DC §7.1, §4.4). The edge is a solid offset
/// block, never a blurred shadow; pressing moves the face down 3 px.
class TactileButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final TactileVariant variant;
  final IconData? icon;
  final bool loading;

  /// Outline variant in an incorrect context uses a coral border and
  /// `errorInk` text (DC §7.1).
  final bool errorTone;
  final bool expand;
  final String? semanticLabel;
  const TactileButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = TactileVariant.primary,
    this.icon,
    this.loading = false,
    this.errorTone = false,
    this.expand = true,
    this.semanticLabel,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _pressed = false, _hover = false, _focused = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  (Color fill, Color edge, Color label, Color? border) _colors(bool hc) {
    if (widget.onPressed == null && !widget.loading) {
      return (SumiColors.disabled, Colors.transparent, SumiColors.disabledText, null);
    }
    return switch (widget.variant) {
      TactileVariant.primary => (
        hc ? SumiColors.hcPrimary : SumiColors.primary,
        SumiColors.primaryShadow,
        Colors.white,
        null,
      ),
      TactileVariant.secondary => (
        hc ? SumiColors.hcSky : SumiColors.sky,
        SumiColors.skyShadow,
        Colors.white,
        null,
      ),
      TactileVariant.danger => (
        hc ? SumiColors.hcCoral : SumiColors.coral,
        SumiColors.coralShadow,
        Colors.white,
        null,
      ),
      TactileVariant.warning => (
        SumiColors.amber,
        SumiColors.amberShadow,
        SumiColors.ink,
        null,
      ),
      TactileVariant.outline => (
        Colors.white,
        SumiColors.borderShadow,
        widget.errorTone ? SumiColors.errorInk : SumiColors.infoInk,
        widget.errorTone ? SumiColors.coral : SumiColors.border,
      ),
      TactileVariant.text => (
        Colors.transparent,
        Colors.transparent,
        widget.errorTone ? SumiColors.errorInk : SumiColors.infoInk,
        null,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final hc = Theme.of(context).colorScheme.primary == SumiColors.hcPrimary;
    final (fill, edge, labelColor, border) = _colors(hc);
    final isText = widget.variant == TactileVariant.text;
    final showEdge = _enabled && !isText;
    final drop = _pressed && _enabled && !isText ? 3.0 : 0.0;
    var face = fill;
    if (_enabled && !isText) {
      if (_pressed) {
        face = widget.variant == TactileVariant.primary && !hc
            ? SumiColors.primaryPressed
            : Color.lerp(fill, Colors.black, .1)!;
      } else if (_hover) {
        face = Color.lerp(fill, Colors.white, .08)!;
      }
    }
    final duration = reduceMotion(context) ? Duration.zero : SumiMotion.press;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: labelColor),
          ),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: labelColor),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: sumiFontFamily,
              fontSize: 15,
              height: 20 / 15,
              letterSpacing: .4,
              fontWeight: FontWeight.w800,
              color: labelColor,
            ),
          ),
        ),
      ],
    );
    final button = SizedBox(
      height: isText ? 48 : 60,
      child: Stack(
        children: [
          if (showEdge)
            Positioned(
              left: 0,
              right: 0,
              top: 4,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: edge,
                  borderRadius: BorderRadius.circular(SumiRadius.r16),
                ),
              ),
            ),
          AnimatedPositioned(
            duration: duration,
            curve: SumiMotion.pressCurve,
            left: 0,
            right: 0,
            top: drop,
            bottom: isText ? 0 : 4 - drop,
            child: AnimatedContainer(
              duration: duration,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: face,
                borderRadius: BorderRadius.circular(SumiRadius.r16),
                border: border == null
                    ? null
                    : Border.all(color: border, width: 2),
              ),
              child: content,
            ),
          ),
          if (_focused)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(SumiRadius.r16 + 2),
                    border: Border.all(color: SumiColors.focusRing, width: 3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTap: _enabled ? widget.onPressed : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: widget.expand ? double.infinity : 120,
            ),
            child: button,
          ),
        ),
      ),
    );
  }
}

/// DC §7.2 graded states for a choice row.
enum ChoiceState { idle, selected, correct, incorrect, rightAnswer }

/// A selectable answer or onboarding option (DC §7.2, LES-13).
class ChoiceRow extends StatefulWidget {
  final String label;
  final String? subtitle;
  final ChoiceState state;
  final VoidCallback? onTap;
  final Widget? leading;

  /// For semantics: "Option {index} of {count}, {label}".
  final int? index, count;
  const ChoiceRow({
    super.key,
    required this.label,
    this.subtitle,
    this.state = ChoiceState.idle,
    this.onTap,
    this.leading,
    this.index,
    this.count,
  });

  @override
  State<ChoiceRow> createState() => _ChoiceRowState();
}

class _ChoiceRowState extends State<ChoiceRow> {
  bool _pressed = false, _hover = false;

  @override
  Widget build(BuildContext context) {
    final (outline, edge, fill, ink, IconData? badge) = switch (widget.state) {
      ChoiceState.idle => (
        SumiColors.border,
        SumiColors.borderShadow,
        _hover ? SumiColors.surfaceSoft : Colors.white,
        SumiColors.ink,
        null,
      ),
      ChoiceState.selected => (
        SumiColors.sky,
        SumiColors.skyShadow,
        SumiColors.skySoft,
        SumiColors.infoInk,
        Icons.check_circle_rounded,
      ),
      ChoiceState.correct => (
        SumiColors.primary,
        SumiColors.primaryShadow,
        SumiColors.primarySoft,
        SumiColors.successInk,
        Icons.check_circle_rounded,
      ),
      ChoiceState.incorrect => (
        SumiColors.coral,
        SumiColors.coralShadow,
        SumiColors.coralSoft,
        SumiColors.errorInk,
        Icons.cancel_rounded,
      ),
      ChoiceState.rightAnswer => (
        SumiColors.primary,
        SumiColors.primaryShadow,
        Colors.white,
        SumiColors.successInk,
        Icons.check_circle_outline_rounded,
      ),
    };
    final enabled = widget.onTap != null;
    final drop = _pressed && enabled ? 2.0 : 0.0;
    final duration = reduceMotion(context) ? Duration.zero : SumiMotion.press;
    final t = Theme.of(context).textTheme;
    final stateWord = switch (widget.state) {
      ChoiceState.selected => 'selected',
      ChoiceState.correct => 'correct',
      ChoiceState.incorrect => 'incorrect',
      ChoiceState.rightAnswer => 'correct answer',
      ChoiceState.idle => null,
    };
    final semantic = [
      if (widget.index != null && widget.count != null)
        'Option ${widget.index} of ${widget.count}',
      widget.label,
      ?widget.subtitle,
      ?stateWord,
    ].join(', ');
    return Semantics(
      button: enabled,
      selected: widget.state == ChoiceState.selected,
      inMutuallyExclusiveGroup: true,
      label: semantic,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: duration,
            margin: EdgeInsets.only(top: drop),
            padding: EdgeInsets.only(bottom: 3 - drop),
            decoration: BoxDecoration(
              color: edge,
              borderRadius: BorderRadius.circular(SumiRadius.r16),
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(SumiRadius.r16),
                border: Border.all(color: outline, width: 2),
              ),
              child: Row(
                children: [
                  if (widget.leading != null) ...[
                    widget.leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: t.titleMedium?.copyWith(color: ink),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(widget.subtitle!, style: t.bodyMedium),
                        ],
                      ],
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 12),
                    Icon(badge, color: outline, size: 24),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// DC §7.3 progress bar with the highlight stripe.
class SumiProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color? color;
  final String semanticLabel;
  final int? semanticValue, semanticMax;
  const SumiProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.color,
    this.semanticLabel = 'Progress',
    this.semanticValue,
    this.semanticMax,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final duration = reduceMotion(context) ? Duration.zero : SumiMotion.micro;
    final label = semanticValue != null && semanticMax != null
        ? '$semanticLabel, $semanticValue of $semanticMax'
        : '$semanticLabel, ${(v * 100).round()} percent';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SumiRadius.pill),
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: SumiColors.disabled),
                ),
                AnimatedContainer(
                  duration: duration,
                  curve: SumiMotion.microCurve,
                  width: box.maxWidth * v,
                  decoration: BoxDecoration(
                    color: color ?? Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(SumiRadius.pill),
                  ),
                ),
                if (v > 0 && height >= 8)
                  Positioned(
                    left: 4,
                    top: (height / 2 - 3).clamp(1.0, 4.0),
                    child: AnimatedContainer(
                      duration: duration,
                      width: (box.maxWidth * v * .6 - 8).clamp(0.0, double.infinity),
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .35),
                        borderRadius: BorderRadius.circular(SumiRadius.pill),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// DC §7.5 card: white, radius 16, 2 px border, 3 px edge when tappable.
class SumiCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final String? semanticLabel;
  const SumiCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.color = Colors.white,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(SumiRadius.r16),
        border: Border.all(color: SumiColors.border, width: 2),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          color: SumiColors.borderShadow,
          borderRadius: BorderRadius.circular(SumiRadius.r16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(SumiRadius.r16),
            onTap: onTap,
            child: card,
          ),
        ),
      ),
    );
  }
}

/// DC §7.7 selectable chip (with a 48 px target).
class SumiChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool prompt;
  const SumiChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.prompt = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: InkWell(
      borderRadius: BorderRadius.circular(SumiRadius.pill),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? SumiColors.skySoft : Colors.white,
            borderRadius: BorderRadius.circular(SumiRadius.pill),
            border: Border.all(
              color: selected ? SumiColors.sky : SumiColors.border,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected || prompt) ...[
                Icon(
                  selected ? Icons.check_rounded : Icons.add_rounded,
                  size: 16,
                  color: selected ? SumiColors.infoInk : SumiColors.mutedStrong,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: sumiFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? SumiColors.infoInk : SumiColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// DC §7.34 empty state.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String heading, body;
  final String? actionLabel, secondaryLabel;
  final VoidCallback? onAction, onSecondary;

  /// Phase 9: an original 120 px illustration; [icon] is the fallback.
  final Widget? illustration;
  const EmptyState({
    super.key,
    this.illustration,
    required this.icon,
    required this.heading,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (illustration != null)
            ExcludeSemantics(child: illustration!)
          else
          ExcludeSemantics(
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: SumiColors.surfaceSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: SumiColors.mutedStrong),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(heading, style: t.titleLarge, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 8),
          Text(body, style: t.bodyLarge?.copyWith(color: SumiColors.mutedStrong), textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 24),
            TactileButton(
              actionLabel!,
              variant: TactileVariant.outline,
              onPressed: onAction,
            ),
          ],
          if (secondaryLabel != null) ...[
            const SizedBox(height: 8),
            TactileButton(
              secondaryLabel!,
              variant: TactileVariant.text,
              onPressed: onSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

/// DC §7.36 inline error with a retry action.
class InlineError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const InlineError(this.message, {super.key, this.onRetry});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SumiColors.coralSoft,
        borderRadius: BorderRadius.circular(SumiRadius.r12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 20, color: SumiColors.errorInk),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: sumiFontFamily,
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                color: SumiColors.errorInk,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: SumiColors.errorInk,
                minimumSize: const Size(48, 48),
              ),
              child: const Text('RETRY'),
            ),
        ],
      ),
    ),
  );
}

/// DC §7.30 settings section label.
class SettingsSectionLabel extends StatelessWidget {
  final String text;
  const SettingsSectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    ),
  );
}

/// DC §7.30 settings row. [subtitle] must be derived from real state (SET-02).
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitch;
  final bool enabled;
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.switchValue,
    this.onSwitch,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final titleStyle = t.bodyLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: enabled ? SumiColors.ink : SumiColors.disabledText,
    );
    final trailing = switchValue != null
        ? Switch(
            value: switchValue!,
            onChanged: enabled ? onSwitch : null,
            activeTrackColor: SumiColors.primary,
          )
        : onTap != null
        ? const Icon(Icons.chevron_right_rounded, color: SumiColors.muted)
        : null;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: enabled ? SumiColors.mutedStrong : SumiColors.disabledText),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                const SizedBox(height: 2),
                Text(subtitle, style: t.bodyMedium),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
    if (switchValue != null) {
      return MergeSemantics(
        child: Semantics(
          toggled: switchValue,
          enabled: enabled,
          child: InkWell(
            onTap: enabled && onSwitch != null
                ? () => onSwitch!(!switchValue!)
                : null,
            child: row,
          ),
        ),
      );
    }
    return Semantics(
      button: onTap != null,
      enabled: enabled,
      child: InkWell(onTap: enabled ? onTap : null, child: row),
    );
  }
}

/// DC §7.38 provider badge: who produced a response (TUT-02).
class ProviderBadge extends StatelessWidget {
  final String text;
  final IconData icon;
  const ProviderBadge({super.key, required this.text, required this.icon});

  factory ProviderBadge.authored() =>
      const ProviderBadge(text: 'AUTHORED', icon: Icons.menu_book_rounded);
  factory ProviderBadge.onDevice(String model) => ProviderBadge(
    text: 'ON-DEVICE · ${model.toUpperCase()}',
    icon: Icons.memory_rounded,
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Response from: $text',
    excludeSemantics: true,
    child: Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: SumiColors.surfaceSoft,
        borderRadius: BorderRadius.circular(SumiRadius.pill),
        border: Border.all(color: SumiColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: SumiColors.mutedStrong),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    ),
  );
}

/// Selection feedback through the effects service (SND-01/02). [enabled] is
/// kept for call sites that pass the record's own setting.
void selectionHaptic(bool enabled) {
  if (!enabled) return;
  EffectsService.instance.feedback(SumiSound.select, SumiHaptic.selection);
}
