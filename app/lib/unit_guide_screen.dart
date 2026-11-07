import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'widgets.dart';
import 'learning_path/learning_path_state.dart';

class UnitGuideScreen extends StatelessWidget {
  final Catalog catalog;
  final LearningState learning;
  final LearningUnit unit;
  final Future<void> Function(Resource) onOpenResource;
  final VoidCallback? onAskTutor;
  final VoidCallback? onStartPractice;

  const UnitGuideScreen({
    super.key,
    required this.catalog,
    required this.learning,
    required this.unit,
    required this.onOpenResource,
    this.onAskTutor,
    this.onStartPractice,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final resources = catalog.resources
        .where((r) => unit.nodes.any((n) => n.resourceId == r.id))
        .toList();
    final videos = resources
        .where((r) => r.type == ResourceType.video)
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: SumiColors.canvas,
        title: Text('Unit Guidebook · ${catalog.title}', style: t.titleMedium),
        actions: [
          if (onAskTutor != null)
            IconButton(
              icon: Icon(Icons.psychology_rounded, color: SumiColors.primary),
              tooltip: 'Ask Sumi Tutor',
              onPressed: onAskTutor,
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: EdgeInsets.all(24),
            children: [
              Surface(
                color: SumiColors.sky,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tag(
                      'UNIT ${unit.index + 1} GUIDE',
                      color: Colors.white,
                      background: Colors.white.withValues(alpha: 0.2),
                    ),
                    SizedBox(height: 12),
                    Text(
                      unit.title,
                      style: t.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      unit.outcome,
                      style: t.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    if (onStartPractice != null) ...[
                      SizedBox(height: 16),
                      ActionButton(
                        'START UNIT PRACTICE',
                        onPressed:
                            unit.nodes.any(
                              (n) => n.prerequisites.every(
                                learning.completed.contains,
                              ),
                            )
                            ? () {
                                Navigator.pop(context);
                                onStartPractice!();
                              }
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 24),

              Text('Watch', style: t.titleLarge),
              if (videos.isEmpty)
                const Text(
                  'Use the written references below. No video is required.',
                ),
              for (final r in videos)
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: Text(r.title),
                  subtitle: Text(r.publisher),
                  onTap: () => onOpenResource(r),
                ),
              const SizedBox(height: 24),
              Text('Key ideas', style: t.titleLarge),
              SizedBox(height: 12),
              for (final m in unit.nodes) ...[
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Surface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.title, style: t.titleMedium),
                        SizedBox(height: 4),
                        Text(m.subtitle, style: t.bodyMedium),
                        if (m.lesson != null && m.lesson!['idea'] != null) ...[
                          SizedBox(height: 8),
                          Text(
                            m.lesson!['idea'],
                            style: t.bodySmall?.copyWith(
                              color: SumiColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              SizedBox(height: 24),
              Text('Reference', style: t.titleLarge),
              SizedBox(height: 12),
              for (final r in resources) ...[
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Surface(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: r.type == ResourceType.video
                                ? Color(0xFFFFEDE5)
                                : SumiColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            r.type == ResourceType.video
                                ? Icons.play_circle_fill_rounded
                                : Icons.article_rounded,
                            color: r.type == ResourceType.video
                                ? Colors.deepOrange
                                : SumiColors.primary,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.title, style: t.titleMedium),
                              SizedBox(height: 2),
                              Text(
                                '${r.publisher} · ${r.durationMinutes} MIN',
                                style: t.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => onOpenResource(r),
                          child: Text('Study'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text('Try', style: t.titleLarge),
              for (final m in unit.nodes)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_note),
                  title: Text(m.lesson?['task'] as String? ?? m.deliverable),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
