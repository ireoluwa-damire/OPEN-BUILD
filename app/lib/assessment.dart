import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

class AssessmentScreen extends StatefulWidget {
  final Catalog catalog;
  final List<Attempt> existing;
  final Future<void> Function(Attempt) onAttempt;
  final String title;
  const AssessmentScreen({
    super.key,
    required this.catalog,
    required this.existing,
    required this.onAttempt,
    this.title = 'Your starting point',
  });
  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen>
    with WidgetsBindingObserver {
  late int index;
  int? answer;
  bool hint = false, checked = false, saving = false;
  final Stopwatch watch = Stopwatch();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final done = widget.existing.map((a) => a.questionId).toSet();
    index = widget.catalog.questions.indexWhere((q) => !done.contains(q.id));
    if (index < 0) index = 0;
    watch.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !checked) {
      watch.start();
    } else {
      watch.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    watch.stop();
    super.dispose();
  }

  Future<void> submit({bool skip = false}) async {
    if (saving || checked) return;
    watch.stop();
    setState(() => saving = true);
    final question = widget.catalog.questions[index];
    try {
      await widget.onAttempt(
        Attempt(
          question.id,
          skip ? null : answer,
          hint,
          watch.elapsedMilliseconds / 1000,
        ),
      );
      if (!mounted) return;
      setState(() {
        checked = true;
        saving = false;
        if (skip) answer = null;
      });
    } catch (_) {
      if (!mounted) return;
      watch.start();
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your answer could not be saved. Please try again.'),
        ),
      );
    }
  }

  Future<void> leave() async {
    if (saving) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Pick this up later?'),
        content: Text(
          'Your checked answers are saved. You can continue from your next question.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('Save and leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.catalog.questions[index];
    final correct = checked && answer == q.correct;
    final t = Theme.of(context).textTheme;
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: SumiColors.canvas,
          leading: IconButton(
            onPressed: saving ? null : leave,
            tooltip: 'Save and leave',
            icon: Icon(Icons.close_rounded),
          ),
          title: Text(widget.title, style: t.titleMedium),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 22),
              child: Center(
                child: Text(
                  '${index + 1} / ${widget.catalog.questions.length}',
                  style: t.bodySmall,
                ),
              ),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value:
                          (index + (checked ? 1 : 0)) /
                          widget.catalog.questions.length,
                      minHeight: 7,
                      backgroundColor: SumiColors.border,
                      color: SumiColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                Icons.explore_rounded,
                                color: SumiColors.primary,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'No pressure to know it all.\nEvery answer helps us find your next step.',
                                style: t.bodySmall,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Tag(q.label),
                        SizedBox(height: 18),
                        Text(
                          q.prompt,
                          style: t.headlineMedium?.copyWith(fontSize: 26),
                        ),
                        SizedBox(height: 22),
                        if (q.code != null) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: SumiColors.ink,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: CodeExample(q.code!, fontSize: 16),
                          ),
                          SizedBox(height: 22),
                        ],
                        ...q.options.indexed.map((entry) {
                          final selected = answer == entry.$1;
                          final reveal = checked && entry.$1 == q.correct;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Semantics(
                              selected: selected,
                              button: true,
                              child: Material(
                                color: reveal
                                    ? Color(0xFFE2F5EC)
                                    : selected
                                    ? SumiColors.primarySoft
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: reveal
                                        ? SumiColors.primary
                                        : selected
                                        ? SumiColors.primary
                                        : SumiColors.border,
                                    width: selected || reveal ? 2 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: checked || saving
                                      ? null
                                      : () => setState(() => answer = entry.$1),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: EdgeInsets.all(18),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? SumiColors.primary
                                                : SumiColors.canvas,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            String.fromCharCode(65 + entry.$1),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              color: selected
                                                  ? Colors.white
                                                  : SumiColors.muted,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            entry.$2,
                                            style: t.bodyMedium,
                                          ),
                                        ),
                                        if (reveal)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: SumiColors.primaryPressed,
                                            size: 22,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        if (checked) ...[
                          SizedBox(height: 12),
                          Surface(
                            color: correct
                                ? Color(0xFFE2F5EC)
                                : Color(0xFFFFEDE5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  correct
                                      ? 'That’s a useful connection.'
                                      : 'Here’s the useful part.',
                                  style: t.titleMedium,
                                ),
                                SizedBox(height: 8),
                                Text(q.explanation, style: t.bodyMedium),
                                if (hint) ...[
                                  SizedBox(height: 8),
                                  Text(
                                    'Saved as a supported attempt because you used a hint.',
                                    style: t.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (hint && !checked)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text(q.hint, style: t.bodyMedium),
                          ),
                        if (!checked)
                          TextButton.icon(
                            onPressed: hint || saving
                                ? null
                                : () => setState(() => hint = true),
                            icon: Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 19,
                            ),
                            label: Text(hint ? 'Hint shown' : 'A little hint'),
                          ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, 20),
                    decoration: BoxDecoration(
                      color: SumiColors.canvas,
                      border: Border(top: BorderSide(color: SumiColors.border)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ActionButton(
                            saving
                                ? 'Saving your answer…'
                                : checked
                                ? index == widget.catalog.questions.length - 1
                                      ? 'See my learning route'
                                      : 'Next small question'
                                : 'Check my answer',
                            onPressed: saving
                                ? null
                                : checked
                                ? () {
                                    if (index ==
                                        widget.catalog.questions.length - 1) {
                                      Navigator.pop(context, true);
                                    } else {
                                      setState(() {
                                        index++;
                                        answer = null;
                                        hint = false;
                                        checked = false;
                                      });
                                      watch
                                        ..reset()
                                        ..start();
                                    }
                                  }
                                : answer == null
                                ? null
                                : () => submit(),
                          ),
                        ),
                        if (!checked)
                          TextButton(
                            onPressed: saving ? null : () => submit(skip: true),
                            child: Text('I’m not sure yet'),
                          ),
                      ],
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
