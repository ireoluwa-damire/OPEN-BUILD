import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

class PracticeScreen extends StatefulWidget {
  final Milestone milestone;
  final Resource resource;
  final bool completed;
  final Future<void> Function() onResource;
  final Future<void> Function(bool demonstrated) onComplete;
  final VoidCallback? onAskTutor;

  const PracticeScreen({
    super.key,
    required this.milestone,
    required this.resource,
    required this.completed,
    required this.onResource,
    required this.onComplete,
    this.onAskTutor,
  });
  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int? selected;
  bool checked = false, taskDone = false, saving = false, finished = false;
  bool? firstCorrect;
  @override
  Widget build(BuildContext context) {
    final lesson = widget.milestone.lesson!;
    final t = Theme.of(context).textTheme;
    final correct = checked && selected == lesson['correct'];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SumiColors.canvas,
        title: Text('One small step', style: t.titleMedium),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SumiColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: SumiColors.primary,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Tag(
                      widget.completed
                          ? 'PROJECT TASK COMPLETED'
                          : 'READ · TRY · MAKE',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(widget.milestone.title, style: t.headlineMedium),
              SizedBox(height: 20),
              Text(lesson['idea'], style: t.titleLarge),
              SizedBox(height: 12),
              Text(lesson['body'], style: t.bodyLarge),
              SizedBox(height: 24),
              Surface(
                color: SumiColors.ink,
                child: Text(
                  lesson['example'],
                  style: TextStyle(color: Colors.white, height: 1.6),
                ),
              ),
              SizedBox(height: 24),
              Text('Try it in a new example', style: t.titleLarge),
              SizedBox(height: 12),
              Text(lesson['prompt'], style: t.bodyLarge),
              SizedBox(height: 12),
              ...List<String>.from(lesson['options']).indexed.map(
                (e) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: selected == e.$1
                          ? SumiColors.primarySoft
                          : Colors.white,
                      alignment: Alignment.centerLeft,
                      side: BorderSide(
                        color: selected == e.$1
                            ? SumiColors.primary
                            : SumiColors.border,
                      ),
                    ),
                    onPressed: checked || finished
                        ? null
                        : () => setState(() => selected = e.$1),
                    child: Text(e.$2, style: TextStyle(color: SumiColors.ink)),
                  ),
                ),
              ),
              if (!checked && !finished)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionButton(
                    'Check this connection',
                    onPressed: selected == null
                        ? null
                        : () => setState(() {
                            checked = true;
                            firstCorrect ??= selected == lesson['correct'];
                          }),
                  ),
                ),
              if (checked) ...[
                SizedBox(height: 10),
                Surface(
                  color: correct ? Color(0xFFE2F5EC) : Color(0xFFFFEDE2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        correct
                            ? 'You connected the pieces.'
                            : 'Let’s look at this together.',
                        style: t.titleMedium,
                      ),
                      SizedBox(height: 8),
                      Text(lesson['explanation']),
                      if (!correct)
                        TextButton(
                          onPressed: () => setState(() {
                            checked = false;
                            selected = null;
                          }),
                          child: Text('Try the connection again'),
                        ),
                      if (widget.onAskTutor != null) ...[
                        SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: widget.onAskTutor,
                          icon: Icon(Icons.psychology_rounded, size: 18),
                          label: Text('Ask AI tutor a contextual follow-up'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              SizedBox(height: 26),
              Surface(
                color: Color(0xFFF9FAFC),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Tag(
                          widget.resource.type.name.toUpperCase(),
                          background: widget.resource.type == ResourceType.video
                              ? Color(0xFFFFEDE5)
                              : SumiColors.primarySoft,
                        ),
                        SizedBox(width: 8),
                        Tag('${widget.resource.durationMinutes} MIN'),
                        Spacer(),
                        Tag(
                          widget.resource.reviewedStatus.name.toUpperCase(),
                          background: Color(0xFFE2F5EC),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'RECOMMENDED FOR THIS STEP',
                      style: t.labelSmall?.copyWith(
                        color: SumiColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(widget.resource.title, style: t.titleMedium),
                    SizedBox(height: 4),
                    Text(widget.resource.whyItHelps, style: t.bodyMedium),
                    SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => widget.onResource(),
                      icon: Icon(Icons.open_in_new_rounded, size: 17),
                      label: Text('View resource details & study'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tag('MAKE SOMETHING SMALL', background: Color(0xFFFFEDE2)),
                    SizedBox(height: 16),
                    Text(lesson['task'], style: t.bodyLarge),
                    SizedBox(height: 10),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: taskDone || widget.completed || finished,
                      onChanged: widget.completed || finished || saving
                          ? null
                          : (v) => setState(() => taskDone = v ?? false),
                      title: Text(
                        'I made this and checked the result.',
                        style: t.bodyMedium,
                      ),
                    ),
                    Text(
                      widget.milestone.id.startsWith('music')
                          ? 'This records your own project work. Sumi does not record audio or inspect files.'
                          : widget.milestone.id.startsWith('fashion')
                          ? 'This records your own project work. Sumi does not inspect camera photos or uploaded files.'
                          : 'This records your own project work. Sumi does not inspect uploaded files or audio.',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              if (!widget.completed && !finished)
                ActionButton(
                  saving
                      ? 'Saving your progress…'
                      : 'Complete this project step',
                  onPressed: !taskDone || !correct || saving
                      ? null
                      : () async {
                          setState(() => saving = true);
                          try {
                            await widget.onComplete(firstCorrect == true);
                            if (mounted) {
                              setState(() {
                                saving = false;
                                finished = true;
                              });
                            }
                          } catch (_) {
                            if (context.mounted) {
                              setState(() => saving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Your progress couldn’t be saved. Try again.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                ),
              if (finished || widget.completed)
                ActionButton(
                  'Back to my learning space',
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
