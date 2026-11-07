import 'package:flutter/material.dart';

import 'theme.dart';

class CodeExample extends StatelessWidget {
  final String code;
  final double fontSize;
  const CodeExample(this.code, {super.key, this.fontSize = 15});
  @override
  Widget build(BuildContext context) => Semantics(
    label: code,
    child: ExcludeSemantics(
      child: SelectableText(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          color: Colors.white,
          height: 1.6,
          fontSize: fontSize,
        ),
      ),
    ),
  );
}

class Surface extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  const Surface({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(24),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: color == Colors.white ? SumiColors.border : Colors.transparent,
      ),
    ),
    child: child,
  );
}

class Tag extends StatelessWidget {
  final String text;
  final Color color, background;
  final IconData? icon;
  const Tag(
    this.text, {
    super.key,
    this.color = SumiColors.primary,
    this.background = SumiColors.primarySoft,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              height: 1.3,
              letterSpacing: .3,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?trailing,
      ],
    ),
  );
}

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  const ActionButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
  });
  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: enabled ? SumiColors.primary : SumiColors.disabled,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: SumiColors.primaryShadow,
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: enabled ? Colors.white : SumiColors.disabledText,
                      ),
                    ),
                  ),
                  SizedBox(width: 14),
                  Icon(
                    icon,
                    size: 18,
                    color: enabled ? Colors.white : SumiColors.disabledText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
