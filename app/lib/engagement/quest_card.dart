import 'package:flutter/material.dart';

import '../design_system/components.dart';
import '../theme.dart';
import 'quests.dart';
import '../graphics/sumi_graphics.dart';

/// GAM-04 (DC §7.28): collapsible daily quests card.
class QuestCard extends StatefulWidget {
  final DailyQuests quests;

  /// The Practice tab uses the violet header variant.
  final bool violet;
  const QuestCard({super.key, required this.quests, this.violet = false});

  @override
  State<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<QuestCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final q = widget.quests;
    return SumiCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: widget.violet ? SumiColors.violetSoft : Colors.white,
      child: Column(
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            label: 'Daily quests, ${q.doneCount} of 3 done',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    const SumiGlyph(SumiGlyphKind.quest, size: 32, color: SumiColors.violet),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Daily quests', style: t.titleMedium)),
                    Text('${q.doneCount}/3', style: t.bodySmall?.copyWith(fontFeatures: tabularFigures)),
                    Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            for (final quest in q.quests)
              Semantics(
                label: '${quest.title}. ${quest.value} of ${quest.target}${quest.done ? ', done' : ''}',
                excludeSemantics: true,
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      Icon(
                        quest.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: quest.done ? SumiColors.successInk : SumiColors.mutedStrong,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quest.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: SumiColors.ink),
                            ),
                            const SizedBox(height: 4),
                            SumiProgressBar(
                              value: quest.value / quest.target,
                              height: 8,
                              color: SumiColors.amber,
                              semanticLabel: quest.title,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${quest.value}/${quest.target}', style: t.bodySmall),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SumiGlyph(
                    SumiGlyphKind.chest,
                    color: q.allDone ? SumiColors.amberShadow : SumiColors.disabledText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      q.allDone ? 'Chest opened: +5 sparks' : 'Finish all three to open the chest (+5 sparks)',
                      style: t.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
