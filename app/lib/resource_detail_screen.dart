import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

class ResourceDetailScreen extends StatefulWidget {
  final Resource resource;
  final LearningState learning;
  final String? reasoning;
  final Future<void> Function(Resource) onOpenResource;
  final Future<void> Function(Resource) onToggleSave;
  final VoidCallback? onTakeCheckActivity;

  const ResourceDetailScreen({
    super.key,
    required this.resource,
    required this.learning,
    this.reasoning,
    required this.onOpenResource,
    required this.onToggleSave,
    this.onTakeCheckActivity,
  });

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  bool isOpening = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = widget.resource;
    final isSaved = widget.learning.savedResourceIds.contains(r.id);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: SumiColors.canvas,
        title: Text('Resource Details', style: t.titleMedium),
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isSaved ? SumiColors.primary : null,
            ),
            tooltip: isSaved ? 'Remove from Saved' : 'Save for later',
            onPressed: () async {
              await widget.onToggleSave(r);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: r.type == ResourceType.video
                          ? Color(0xFFFFEDE5)
                          : SumiColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          r.type == ResourceType.video
                              ? Icons.play_circle_fill_rounded
                              : Icons.article_rounded,
                          size: 18,
                          color: r.type == ResourceType.video
                              ? Colors.deepOrange
                              : SumiColors.primary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          r.type.name.toUpperCase(),
                          style: t.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: r.type == ResourceType.video
                                ? Colors.deepOrange
                                : SumiColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Tag('${r.durationMinutes} MIN'),
                  Spacer(),
                  Tag(
                    r.reviewedStatus.name.toUpperCase(),
                    background: Color(0xFFE2F5EC),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(r.title, style: t.headlineMedium),
              SizedBox(height: 8),
              Text(
                'By ${r.creator} · Published by ${r.publisher}',
                style: t.bodySmall,
              ),
              SizedBox(height: 20),
              if (widget.reasoning != null && widget.reasoning!.isNotEmpty) ...[
                Surface(
                  color: SumiColors.primarySoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECOMMENDED FOR THIS STEP',
                        style: t.labelSmall?.copyWith(
                          color: SumiColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(widget.reasoning!, style: t.bodyMedium),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WHY THIS HELPS', style: t.titleMedium),
                    SizedBox(height: 8),
                    Text(r.whyItHelps, style: t.bodyLarge),
                    if (r.description.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Text(r.description, style: t.bodyMedium),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 20),
              Surface(
                color: Color(0xFFF7F8FA),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: SumiColors.muted,
                        ),
                        SizedBox(width: 8),
                        Text('OBSERVATION DISCLOSURE', style: t.labelSmall),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sumi opens external resources in your default system browser or video app. Sumi does not observe watch percentage or playback speed. Capability evidence changes only when you complete the post-resource check activity.',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              ActionButton(
                isOpening
                    ? 'Opening external player…'
                    : 'Open resource in external app',
                icon: Icons.open_in_new_rounded,
                onPressed: isOpening
                    ? null
                    : () async {
                        setState(() => isOpening = true);
                        try {
                          await widget.onOpenResource(r);
                        } finally {
                          if (mounted) setState(() => isOpening = false);
                        }
                      },
              ),
              if (widget.onTakeCheckActivity != null) ...[
                SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: SumiColors.primary),
                  ),
                  onPressed: widget.onTakeCheckActivity,
                  icon: Icon(
                    Icons.check_circle_outline_rounded,
                    color: SumiColors.primary,
                  ),
                  label: Text(
                    'I’ve reviewed this · Take check activity',
                    style: TextStyle(
                      color: SumiColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
