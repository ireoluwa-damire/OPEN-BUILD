import 'package:flutter/material.dart';

import '../design_system/components.dart';
import '../models.dart';
import '../resource_system.dart';
import '../theme.dart';
import '../widgets.dart';
import '../graphics/sumi_graphics.dart';

/// LIB-01 to LIB-04. Saves and preferences go through use cases; viewing a
/// resource never adds evidence, points or streak credit.
class LibraryTab extends StatefulWidget {
  final Catalog catalog;
  final List<Catalog> allDisciplines;
  final LearningState learning;
  final ResourceRepository repository;
  final ResourceRanker ranker;
  final Future<void> Function(Resource) onOpenResourceDetail;
  final Future<void> Function(Resource) onToggleSave;

  /// One preference change through `UpdateSetting` (ARC-01).
  final Future<void> Function(void Function(LearningState s) change) onUpdate;

  const LibraryTab({
    super.key,
    required this.catalog,
    required this.allDisciplines,
    required this.learning,
    required this.repository,
    required this.ranker,
    required this.onOpenResourceDetail,
    required this.onToggleSave,
    required this.onUpdate,
  });

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  int activeGroupIndex =
      0; // 0: Recommended, 1: Saved, 2: Recently Used, 3: Browse by Discipline

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final allResources = widget.repository.getAllResources();
    final recommendations = widget.ranker.rank(
      candidates: widget.repository.getAllResources(
        discipline: widget.catalog.id,
      ),
      state: widget.learning,
      catalog: widget.catalog,
    );

    final savedResources = allResources
        .where((r) => widget.learning.savedResourceIds.contains(r.id))
        .toList();
    final recentResources = widget.learning.recentlyUsedResourceIds
        .map((id) => widget.repository.getResourceById(id))
        .whereType<Resource>()
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Library', style: t.titleMedium)),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          // Format Preference & Data Saver Bar
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Format preference:',
                      style: t.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    DropdownButton<String?>(
                      value: widget.learning.preferredFormatOverride,
                      hint: Text('Auto (Evidence)'),
                      underline: SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Auto (Evidence Adapt)'),
                        ),
                        DropdownMenuItem(
                          value: 'video',
                          child: Text('Video preferred'),
                        ),
                        DropdownMenuItem(
                          value: 'article',
                          child: Text('Article preferred'),
                        ),
                      ],
                      onChanged: (val) async {
                        await widget.onUpdate(
                          (s) => s.preferredFormatOverride = val,
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                    Spacer(),
                    Text(
                      'Data Saver:',
                      style: t.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: widget.learning.dataSavingMode,
                      onChanged: (val) async {
                        await widget.onUpdate((s) => s.dataSavingMode = val);
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Group Selection Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('Recommended for you'),
                  selected: activeGroupIndex == 0,
                  onSelected: (_) => setState(() => activeGroupIndex = 0),
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Saved (${savedResources.length})'),
                  selected: activeGroupIndex == 1,
                  onSelected: (_) => setState(() => activeGroupIndex = 1),
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Used recently (${recentResources.length})'),
                  selected: activeGroupIndex == 2,
                  onSelected: (_) => setState(() => activeGroupIndex = 2),
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Browse by discipline'),
                  selected: activeGroupIndex == 3,
                  onSelected: (_) => setState(() => activeGroupIndex = 3),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          if (activeGroupIndex == 0) ...[
            Text('Recommended for you', style: t.titleLarge),
            SizedBox(height: 12),
            if (recommendations.isEmpty)
              Text(
                'No recommendations match current filter criteria.',
                style: t.bodyMedium,
              )
            else
              for (final rec in recommendations)
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: _ResourceCard(
                    resource: rec.resource,
                    reasoning: rec.reasoning,
                    isSaved: widget.learning.savedResourceIds.contains(
                      rec.resource.id,
                    ),
                    onTap: () => widget.onOpenResourceDetail(rec.resource),
                    onToggleSave: () => widget.onToggleSave(rec.resource),
                  ),
                ),
          ] else if (activeGroupIndex == 1) ...[
            Text('Saved Resources', style: t.titleLarge),
            SizedBox(height: 12),
            if (savedResources.isEmpty)
              const EmptyState(
                illustration: SumiEmptyIllustration(SumiEmptyKind.nothingSaved),
                icon: Icons.bookmark_border_rounded,
                heading: 'Nothing saved yet',
                body: 'Tap SAVE on any resource to keep it here.',
              )
            else
              for (final r in savedResources)
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: _ResourceCard(
                    resource: r,
                    isSaved: true,
                    onTap: () => widget.onOpenResourceDetail(r),
                    onToggleSave: () => widget.onToggleSave(r),
                  ),
                ),
          ] else if (activeGroupIndex == 2) ...[
            Text('Used Recently', style: t.titleLarge),
            SizedBox(height: 12),
            if (recentResources.isEmpty)
              const EmptyState(
                icon: Icons.history_rounded,
                heading: 'Nothing opened yet',
                body: 'Resources you open from Sumi appear here.',
              )
            else
              for (final r in recentResources)
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: _ResourceCard(
                    resource: r,
                    isSaved: widget.learning.savedResourceIds.contains(r.id),
                    onTap: () => widget.onOpenResourceDetail(r),
                    onToggleSave: () => widget.onToggleSave(r),
                  ),
                ),
          ] else if (activeGroupIndex == 3) ...[
            Text('Browse by Discipline', style: t.titleLarge),
            SizedBox(height: 12),
            for (final d in widget.allDisciplines) ...[
              Text(d.title, style: t.titleMedium),
              SizedBox(height: 8),
              for (final r in d.resources)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _ResourceCard(
                    resource: r,
                    isSaved: widget.learning.savedResourceIds.contains(r.id),
                    onTap: () => widget.onOpenResourceDetail(r),
                    onToggleSave: () => widget.onToggleSave(r),
                  ),
                ),
              SizedBox(height: 16),
            ],
          ],
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final Resource resource;
  final String? reasoning;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

  const _ResourceCard({
    required this.resource,
    this.reasoning,
    required this.isSaved,
    required this.onTap,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = resource;
    return Surface(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Tag(
                  r.type.name.toUpperCase(),
                  background: r.type == ResourceType.video
                      ? SumiColors.coralSoft
                      : SumiColors.primarySoft,
                ),
                SizedBox(width: 8),
                Tag('${r.durationMinutes} MIN'),
                Spacer(),
                IconButton(
                  tooltip: isSaved ? 'Remove from saved' : 'Save',
                  icon: Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isSaved ? SumiColors.primary : null,
                    size: 20,
                  ),
                  onPressed: onToggleSave,
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(r.title, style: t.titleMedium),
            SizedBox(height: 4),
            Text('${r.publisher} · ${r.creator}', style: t.bodySmall),
            if (reasoning != null && reasoning!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                reasoning!,
                style: t.bodySmall?.copyWith(
                  color: SumiColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onToggleSave,
                child: Text(isSaved ? 'SAVED' : 'SAVE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

