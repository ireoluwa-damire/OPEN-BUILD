import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import 'challenge_definition.dart';

sealed class ChallengeIntent {
  const ChallengeIntent();
}

class ResponseChanged extends ChallengeIntent {
  final Json response;
  const ResponseChanged(this.response);
}

/// Text colour for each feedback state (DC §2.3 `*Ink` tokens).
Color feedbackColor(FeedbackState state) => switch (state) {
  FeedbackState.correct => SumiColors.successInk,
  FeedbackState.incorrect => SumiColors.errorInk,
  FeedbackState.nearCorrect => SumiColors.warningInk,
  FeedbackState.retry => SumiColors.infoInk,
  FeedbackState.hidden => SumiColors.ink,
};

class ChallengeRenderContext {
  final ChallengeDefinition challenge;
  final Json draft;
  final FeedbackState feedback;
  final bool readOnly, reducedMotion;
  final void Function(ChallengeIntent) emit;
  final Future<void> Function() openResource;
  const ChallengeRenderContext({
    required this.challenge,
    required this.draft,
    required this.feedback,
    required this.readOnly,
    required this.emit,
    required this.openResource,
    this.reducedMotion = false,
  });
  void change(Json response) {
    if (!readOnly) emit(ResponseChanged(response));
  }

  Color get color => feedback == FeedbackState.hidden
      ? SumiColors.sky
      : feedbackColor(feedback);
}

typedef ChallengeBuilder = Widget Function(ChallengeRenderContext context);

class ChallengeRendererRegistry {
  static final Map<ChallengeKind, ChallengeBuilder> renderers =
      Map.unmodifiable({
        ChallengeKind.singleSelect: (c) =>
            SingleSelectChallengeRenderer(data: c),
        ChallengeKind.sequenceTokens: (c) =>
            SequenceTokensChallengeRenderer(data: c),
        ChallengeKind.matchPairs: (c) => MatchPairsChallengeRenderer(data: c),
        ChallengeKind.typedReflection: (c) =>
            TypedReflectionChallengeRenderer(data: c),
        ChallengeKind.mediaObservation: (c) =>
            MediaObservationChallengeRenderer(data: c),
        ChallengeKind.musicImitate: (c) =>
            MusicListenOrImitateChallengeRenderer(data: c),
        ChallengeKind.fashionProcedure: (c) =>
            FashionProcedureOrderChallengeRenderer(data: c),
        ChallengeKind.drawing: (c) =>
            DrawingOrAnnotationChallengeRenderer(data: c),
        ChallengeKind.projectReflection: (c) =>
            ProjectReflectionChallengeRenderer(data: c),
      });
  static Widget build(ChallengeRenderContext data) => KeyedSubtree(
    key: ValueKey('${data.challenge.id}:${data.feedback.name}'),
    child: renderers[data.challenge.kind]!(data),
  );
}

class SingleSelectChallengeRenderer extends StatelessWidget {
  final ChallengeRenderContext data;
  const SingleSelectChallengeRenderer({super.key, required this.data});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < data.challenge.options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Semantics(
            selected: data.draft['choice'] == i,
            child: OutlinedButton(
              onPressed: data.readOnly
                  ? null
                  : () => data.change({'choice': i}),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size(double.infinity, 56),
                foregroundColor: data.draft['choice'] == i
                    ? data.color
                    : SumiColors.ink,
                disabledForegroundColor: data.draft['choice'] == i
                    ? data.color
                    : SumiColors.muted,
                backgroundColor: data.draft['choice'] == i
                    ? data.color.withValues(alpha: .10)
                    : Colors.white,
                side: BorderSide(
                  width: 2,
                  color: data.draft['choice'] == i
                      ? data.color
                      : SumiColors.border,
                ),
              ),
              child: Text(data.challenge.options[i]),
            ),
          ),
        ),
    ],
  );
}

class SequenceTokensChallengeRenderer extends StatelessWidget {
  final ChallengeRenderContext data;
  const SequenceTokensChallengeRenderer({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final order = List<int>.from(data.draft['order'] ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(minHeight: 76),
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: order.isEmpty
              ? const Text('Tap the tokens in order.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < order.length; i++)
                      InputChip(
                        label: Text(data.challenge.options[order[i]]),
                        onDeleted: data.readOnly
                            ? null
                            : () {
                                order.removeAt(i);
                                data.change({'order': order});
                              },
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < data.challenge.options.length; i++)
              OutlinedButton(
                onPressed: data.readOnly || order.contains(i)
                    ? null
                    : () => data.change({
                        'order': [...order, i],
                      }),
                child: Text(data.challenge.options[i]),
              ),
          ],
        ),
      ],
    );
  }
}

class FashionProcedureOrderChallengeRenderer extends StatelessWidget {
  final ChallengeRenderContext data;
  const FashionProcedureOrderChallengeRenderer({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final order = List<int>.from(data.draft['order'] ?? []);
    return Column(
      children: [
        for (var i = 0; i < order.length; i++)
          ListTile(
            leading: CircleAvatar(radius: 16, child: Text('${i + 1}')),
            title: Text(data.challenge.options[order[i]]),
            trailing: IconButton(
              tooltip: 'Remove step ${i + 1}',
              onPressed: data.readOnly
                  ? null
                  : () {
                      order.removeAt(i);
                      data.change({'order': order});
                    },
              icon: const Icon(Icons.undo_rounded),
            ),
          ),
        if (order.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Choose the first step, then the next.'),
          ),
        for (var i = 0; i < data.challenge.options.length; i++)
          if (!order.contains(i))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                onPressed: data.readOnly
                    ? null
                    : () => data.change({
                        'order': [...order, i],
                      }),
                icon: const Icon(Icons.add_rounded),
                label: Text(data.challenge.options[i]),
              ),
            ),
      ],
    );
  }
}

class MatchPairsChallengeRenderer extends StatelessWidget {
  final ChallengeRenderContext data;
  const MatchPairsChallengeRenderer({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final right = List<String>.from(data.challenge.content['right']);
    final pairs = List<int>.from(
      data.draft['pairs'] ?? List.filled(right.length, -1),
    );
    return Column(
      children: [
        for (var i = 0; i < pairs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: DropdownButtonFormField<int>(
              key: ValueKey('${data.challenge.id}:$i:${pairs[i]}'),
              initialValue: pairs[i] < 0 ? null : pairs[i],
              isExpanded: true,
              decoration: InputDecoration(
                labelText: data.challenge.options[i],
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: data.color, width: 2),
                ),
                fillColor: data.feedback == FeedbackState.hidden
                    ? null
                    : data.color.withValues(alpha: .08),
              ),
              hint: const Text('Match a meaning'),
              items: [
                for (var r = 0; r < right.length; r++)
                  DropdownMenuItem(
                    value: r,
                    enabled: pairs[i] == r || !pairs.contains(r),
                    child: Text(right[r]),
                  ),
              ],
              onChanged: data.readOnly
                  ? null
                  : (v) {
                      if (v != null) {
                        pairs[i] = v;
                        data.change({'pairs': pairs});
                      }
                    },
            ),
          ),
      ],
    );
  }
}

class _ResponseField extends StatefulWidget {
  final ChallengeRenderContext data;
  final String label;
  final String field;
  final int minLines;
  const _ResponseField({
    required this.data,
    required this.label,
    this.field = 'text',
    this.minLines = 3,
  });
  @override
  State<_ResponseField> createState() => _ResponseFieldState();
}

class _ResponseFieldState extends State<_ResponseField> {
  late final controller = TextEditingController(
    text: widget.data.draft[widget.field] as String? ?? '',
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ResponseField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = widget.data.draft[widget.field] as String? ?? '';
    if (controller.text != value) {
      controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    readOnly: widget.data.readOnly,
    minLines: widget.minLines,
    maxLines: 5,
    maxLength: 2000,
    decoration: InputDecoration(
      labelText: widget.label,
      alignLabelWithHint: true,
    ),
    onChanged: (v) =>
        widget.data.change({...widget.data.draft, widget.field: v}),
  );
}

/// LES-21: project evidence needs three short, specific fields. A checkbox
/// alone can never complete a project node. Always self-reported.
class ProjectReflectionChallengeRenderer extends StatelessWidget {
  final ChallengeRenderContext data;
  const ProjectReflectionChallengeRenderer({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final rubric = List<String>.from(
      data.challenge.content['rubric'] as List? ?? const [],
    );
    final task = data.challenge.content['task'] as String? ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (task.isNotEmpty) ...[
          Text(task, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
        ],
        for (final (i, field) in ChallengeDefinition.projectFields.indexed) ...[
          _ResponseField(
            data: data,
            field: field,
            minLines: 2,
            label: ChallengeDefinition.projectLabels[i],
          ),
          const SizedBox(height: 8),
        ],
        if (rubric.isNotEmpty) ...[
          Text(
            'SELF-CHECK',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in rubric)
                FilterChip(
                  label: Text(r),
                  selected: (data.draft['rubric'] as List? ?? []).contains(r),
                  onSelected: data.readOnly
                      ? null
                      : (v) {
                          final next = List<String>.from(
                            data.draft['rubric'] as List? ?? [],
                          );
                          v ? next.add(r) : next.remove(r);
                          data.change({...data.draft, 'rubric': next});
                        },
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Text(
          'This records your reflection and project evidence. Sumi does not independently verify the finished work in this demo.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class TypedReflectionChallengeRenderer extends StatelessWidget {
  final ChallengeRenderContext data;
  const TypedReflectionChallengeRenderer({super.key, required this.data});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        data.challenge.content['task'] as String? ?? '',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 20),
      _ResponseField(data: data, label: 'My practice reflection'),
      const Text(
        'At least 12 characters. Your report is saved as an observation.',
      ),
    ],
  );
}

class MediaObservationChallengeRenderer extends StatelessWidget {
  final ChallengeRenderContext data;
  const MediaObservationChallengeRenderer({super.key, required this.data});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SumiColors.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(data.challenge.content['reference'] as String? ?? ''),
      ),
      TextButton.icon(
        onPressed: data.openResource,
        icon: const Icon(Icons.menu_book_rounded),
        label: const Text('Open full reference'),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('I studied the reference above or its source.'),
        value: data.draft['observed'] == true,
        onChanged: data.readOnly
            ? null
            : (v) => data.change({...data.draft, 'observed': v}),
      ),
      _ResponseField(data: data, label: 'What I noticed'),
    ],
  );
}

class MusicListenOrImitateChallengeRenderer extends StatefulWidget {
  final ChallengeRenderContext data;
  const MusicListenOrImitateChallengeRenderer({super.key, required this.data});
  @override
  State<MusicListenOrImitateChallengeRenderer> createState() =>
      _MusicRendererState();
}

class _MusicRendererState extends State<MusicListenOrImitateChallengeRenderer> {
  Timer? timer;
  int beat = 0;
  void watch() {
    timer?.cancel();
    setState(() => beat = 1);
    timer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (!mounted) return;
      setState(() => beat = beat < 4 ? beat + 1 : 0);
      if (beat == 0) t.cancel();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final taps = List<num>.from(data.draft['taps'] ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          label: beat == 0 ? 'Beat guide ready' : 'Beat $beat',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 1; i <= 4; i++)
                CircleAvatar(
                  radius: 24,
                  backgroundColor: beat == i
                      ? SumiColors.sky
                      : SumiColors.surfaceSoft,
                  child: Text('$i'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: data.readOnly ? null : watch,
          child: const Text('WATCH BEAT GUIDE'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: data.readOnly || taps.length >= 5
              ? null
              : () => data.change({
                  'taps': [...taps, DateTime.now().millisecondsSinceEpoch],
                  'accessible': false,
                }),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 88),
          ),
          child: Text('TAP · ${taps.length}/5'),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              onPressed: data.readOnly ? null : () => data.change({}),
              child: const Text('Reset taps'),
            ),
            TextButton(
              onPressed: data.readOnly
                  ? null
                  : () => data.change({'retry': true}),
              child: const Text('I need another try'),
            ),
          ],
        ),
        TextButton(
          onPressed: data.readOnly
              ? null
              : () => data.change({
                  'accessible': true,
                  'taps': [0, 1, 2, 3, 4],
                }),
          child: const Text('Accessible option: I counted the beats'),
        ),
        const Text(
          'Visual beat guide. Screen-tap timing only; no microphone recording.',
        ),
      ],
    );
  }
}

class DrawingOrAnnotationChallengeRenderer extends StatelessWidget {
  final ChallengeRenderContext data;
  const DrawingOrAnnotationChallengeRenderer({super.key, required this.data});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LayoutBuilder(
        builder: (context, box) => GestureDetector(
          onPanStart: data.readOnly
              ? null
              : (d) => _point(d.localPosition, box.maxWidth),
          onPanUpdate: data.readOnly
              ? null
              : (d) => _point(d.localPosition, box.maxWidth),
          child: Semantics(
            label:
                'Seam sketch canvas. The Add seam line button provides a keyboard alternative.',
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: SumiColors.surfaceSoft,
                border: Border.all(color: data.color),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                painter: _SketchPainter(
                  List.from(data.draft['points'] ?? []),
                  data.color,
                ),
              ),
            ),
          ),
        ),
      ),
      Wrap(
        children: [
          TextButton(
            onPressed: data.readOnly
                ? null
                : () => data.change({
                    ...data.draft,
                    'points': [
                      [.2, .2],
                      [.5, .5],
                      [.8, .8],
                    ],
                    'accessible': true,
                  }),
            child: const Text('Add seam line'),
          ),
          TextButton(
            onPressed: data.readOnly
                ? null
                : () => data.change({...data.draft, 'points': []}),
            child: const Text('Clear sketch'),
          ),
        ],
      ),
      _ResponseField(data: data, label: 'Label / what I would inspect'),
    ],
  );
  void _point(Offset p, double width) {
    final points = List.from(data.draft['points'] ?? []);
    if (points.length >= 500) return;
    data.change({
      ...data.draft,
      'points': [
        ...points,
        [(p.dx / width).clamp(0, 1), (p.dy / 150).clamp(0, 1)],
      ],
    });
  }
}

class _SketchPainter extends CustomPainter {
  final List points;
  final Color color;
  _SketchPainter(this.points, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i] as List;
      if (i == 0) {
        path.moveTo(p[0] * size.width, p[1] * size.height);
      } else {
        path.lineTo(p[0] * size.width, p[1] * size.height);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SketchPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
