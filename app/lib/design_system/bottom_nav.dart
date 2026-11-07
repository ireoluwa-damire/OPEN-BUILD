import 'package:flutter/material.dart';

import '../theme.dart';

class SumiNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const SumiNavItem(this.label, this.icon, this.selectedIcon);
}

/// Four labelled destinations with muted unselected items and a tinted tile
/// behind the selected icon (DC §7.10, SHL-02, CF-14).
class SumiBottomNav extends StatelessWidget {
  static const items = [
    SumiNavItem('Learn', Icons.school_outlined, Icons.school_rounded),
    SumiNavItem('Practice', Icons.bolt_outlined, Icons.bolt_rounded),
    SumiNavItem('Library', Icons.menu_book_outlined, Icons.menu_book_rounded),
    SumiNavItem('Profile', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const SumiBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: SumiColors.surface,
        border: Border(top: BorderSide(color: SumiColors.border, width: 2)),
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavSlot(
                  item: items[i],
                  index: i,
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavSlot extends StatefulWidget {
  final SumiNavItem item;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  const _NavSlot({
    required this.item,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavSlot> createState() => _NavSlotState();
}

class _NavSlotState extends State<_NavSlot> {
  bool _hover = false, _focus = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? SumiColors.infoInk : SumiColors.muted;
    return Semantics(
      label: '${widget.item.label}, tab, ${widget.index + 1} of 4',
      selected: widget.selected,
      button: true,
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            decoration: _focus
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(SumiRadius.r12),
                    border: Border.all(color: SumiColors.focusRing, width: 3),
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.selected
                        ? SumiColors.skySoft
                        : _hover
                        ? SumiColors.surfaceSoft
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(SumiRadius.r12),
                    border: widget.selected
                        ? Border.all(color: SumiColors.sky, width: 2)
                        : null,
                  ),
                  child: Icon(
                    widget.selected
                        ? widget.item.selectedIcon
                        : widget.item.icon,
                    size: 24,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: sumiFontFamily,
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w700,
                    color: color,
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
