import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets.dart';
import 'theme.dart';

class TwoDayReview extends StatelessWidget {
  final Catalog catalog;
  final LearningState state;
  final VoidCallback onRecall;
  final Future<void> Function(Json) onFeedback;
  const TwoDayReview({
    super.key,
    required this.catalog,
    required this.state,
    required this.onRecall,
    required this.onFeedback,
  });

  Future<void> feedback(BuildContext context) async {
    int? ease = state.demoFeedback?['ease'],
        clarity = state.demoFeedback?['clarity'];
    int? useful = state.demoFeedback?['coach_usefulness'];
    final notes = TextEditingController(
      text: state.demoFeedback?['notes'] ?? '',
    );
    final result = await showDialog<Json>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) {
          Widget rating(
            String title,
            int? value,
            void Function(int?) set, {
            bool optional = false,
          }) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              Text(
                '1 = difficult / unhelpful · 5 = clear / useful',
                style: Theme.of(dialog).textTheme.bodySmall,
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (var n = 1; n <= 5; n++)
                    ChoiceChip(
                      label: Text('$n'),
                      selected: value == n,
                      onSelected: (_) => update(() => set(n)),
                    ),
                  if (optional)
                    ChoiceChip(
                      label: Text('Not tried'),
                      selected: value == null,
                      onSelected: (_) => update(() => set(null)),
                    ),
                ],
              ),
              SizedBox(height: 12),
            ],
          );
          return AlertDialog(
            title: Text('Two-day demo feedback'),
            scrollable: true,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved only with this discipline on this device. No feedback is sent automatically.',
                ),
                SizedBox(height: 16),
                rating('How easy was navigation?', ease, (n) => ease = n),
                rating(
                  'How clear were the questions?',
                  clarity,
                  (n) => clarity = n,
                ),
                rating(
                  'How useful was the on-device coach?',
                  useful,
                  (n) => useful = n,
                  optional: true,
                ),
                TextField(
                  controller: notes,
                  maxLength: 1000,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'What worked, broke, or confused you?',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: Text('Cancel'),
              ),
              FilledButton(
                onPressed: ease == null || clarity == null
                    ? null
                    : () => Navigator.pop(dialog, {
                        'ease': ease,
                        'clarity': clarity,
                        'coach_usefulness': useful,
                        'notes': notes.text.trim(),
                        'recorded_at': DateTime.now().toIso8601String(),
                      }),
                child: Text('Save feedback'),
              ),
            ],
          );
        },
      ),
    );
    Future<void>.delayed(Duration(milliseconds: 400), notes.dispose);
    if (result != null) await onFeedback(result);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tag('TWO-DAY DEMO'),
          SizedBox(height: 14),
          Text('Try it. Return. Tell us.', style: t.titleLarge),
          SizedBox(height: 12),
          Text(
            'Day 1: choose a goal, find your starting point, try a project step, and set up the optional phone model.',
          ),
          SizedBox(height: 10),
          Text(
            'Day 2: try new examples, review the route, test AI with connectivity off, and record usability feedback.',
          ),
          SizedBox(height: 12),
          Text(
            'Two days tests the product experience. It does not establish mastery or long-term learning speed.',
            style: t.bodySmall,
          ),
          SizedBox(height: 12),
          if (state.recallDone(catalog)) ...[
            Text(
              'Follow-up: ${state.recallIndependent(catalog).length}/${catalog.recallQuestions.length} independent connections.',
            ),
            if (state.earlyRecall)
              Text(
                'EARLY TEST · completed less than 24 hours after starting. This is not a 24-hour retention result.',
                style: TextStyle(color: SumiColors.coral),
              ),
          ] else
            OutlinedButton.icon(
              onPressed: state.baselineDone(catalog) ? onRecall : null,
              icon: Icon(Icons.replay_rounded),
              label: Text(
                state.recallAttempts.isEmpty
                    ? 'Try Day 2 new examples'
                    : 'Continue Day 2 check-in',
              ),
            ),
          if (!state.recallDone(catalog))
            Text(
              'For usability testing you may try Day 2 early; it will be marked as an early test.',
              style: t.bodySmall,
            ),
          SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => feedback(context),
            icon: Icon(Icons.rate_review_outlined),
            label: Text(
              state.demoFeedback == null
                  ? 'Record demo feedback'
                  : 'Update demo feedback',
            ),
          ),
          if (state.demoFeedback != null)
            Text('Feedback saved on this device.', style: t.bodySmall),
        ],
      ),
    );
  }
}
