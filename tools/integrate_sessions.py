from pathlib import Path

root = Path(__file__).resolve().parents[1]
lib = root / 'app/lib'
p = lib / 'main.dart'
s = p.read_text(encoding='utf-8-sig')
s = s.replace("import 'path_widgets.dart';", "import 'learning_path/path_screen.dart';\nimport 'learning_path/learning_path_state.dart';\nimport 'learning_session/learning_session_controller.dart';")
for line in ["import 'adaptation_system.dart';\n", "import 'tutor_system.dart';\n", "import 'practice.dart';\n", "import 'unit_guide_screen.dart';\n"]:
    s = s.replace(line, '')
s = s.replace('  void openTutorChat() {\n    Navigator.push(', '  Future<void> openTutorChat([String? initialPrompt]) async {\n    await Navigator.push(')
s = s.replace('builder: (_) => TutorChatScreen(\n', 'builder: (_) => TutorChatScreen(\n          initialPrompt: initialPrompt,\n', 1)
start = s.index('    await Navigator.push(', s.index('  Future<void> openMilestone('))
end = s.index('\n  @override\n  Widget build', start)
s = s[:start] + '''    LearningSessionController? session;
    try {
      final unit = LearningUnit.forCatalog(c).firstWhere((u) => u.nodes.any((n) => n.id == milestone.id));
      session = await LearningSessionController.open(store: store, learning: learning,
        catalog: c, node: milestone, unitId: unit.id);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ChallengeScreen(
        controller: session!,
        onOpenResource: () => openResourceDetail(topRec?.resource ?? c.resource(milestone.resourceId), reasoning: topRec?.reasoning),
        onAskTutor: (prompt) => openTutorChat(prompt),
      )));
    } catch (_) {
      message('This lesson could not be saved or opened. Your progress is unchanged. Try again.');
    } finally {
      session?.dispose();
      if (mounted) setState(() {});
    }
  }
''' + s[end:]
s = s.replace('          LearnTab(\n', "          LearnTab(\n            key: ValueKey(catalog!.id),\n            store: store,\n            onOpenResource: (r) => openResourceDetail(r),\n")
start = s.index('class LearnTab extends StatefulWidget')
end = s.index('class PracticeTab', start)
s = s[:start] + '''class LearnTab extends PathScreen {
  const LearnTab({super.key, required super.catalog, required super.learning,
    required super.store, required super.onOpenMilestone, required super.onOpenResource,
    required super.onAssess, required super.onAskTutor});
}

''' + s[end:]
p.write_text(s, encoding='utf-8')
(lib / 'path_widgets.dart').write_text("export 'learning_path/path_screen.dart' show UnitHeaderCard, PathNodeWidget, SerpentinePath, NodeActionOverlay;\n", encoding='utf-8')
p = lib / 'models.dart'
s = p.read_text(encoding='utf-8')
s = s[:s.index('\nenum AccoladeType {')] + '\n'
p.write_text(s, encoding='utf-8')
for name in ['services.dart', 'tutor_system.dart', 'tutor_chat_screen.dart']:
    p = lib / name
    s = p.read_text(encoding='utf-8')
    s = "import 'on_device.dart';\n" + s
    p.write_text(s, encoding='utf-8')
p = lib / 'tutor_chat_screen.dart'
s = p.read_text(encoding='utf-8')
s = s.replace('  final Catalog catalog;', '  final String? initialPrompt;\n  final Catalog catalog;', 1)
s = s.replace('    super.key,', '    super.key,\n    this.initialPrompt,', 1)
s = s.replace('    super.initState();', "    super.initState();\n    inputController.text = widget.initialPrompt ?? '';", 1)
s = s.replace('maxWidth: MediaQuery.of(context).size.width * 0.85,', 'constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),')
p.write_text(s, encoding='utf-8')
