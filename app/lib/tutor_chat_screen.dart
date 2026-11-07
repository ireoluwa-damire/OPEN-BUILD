import 'on_device.dart';
import 'package:flutter/material.dart';
import 'models.dart';
import 'design_system/components.dart';
import 'tutor_system.dart';
import 'resource_system.dart';
import 'theme.dart';
import 'widgets.dart';

class TutorChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final TutorProviderType providerType;
  final String modelName;
  final DateTime timestamp;

  TutorChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.providerType = TutorProviderType.fallback,
    this.modelName = 'Authored Guidance',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class TutorChatScreen extends StatefulWidget {
  final String? initialPrompt;
  final Catalog catalog;
  final LearningState learning;
  final ResourceRepository repository;
  final PhoneModelController phoneCoach;
  final Future<void> Function() onPersist;

  const TutorChatScreen({
    super.key,
    this.initialPrompt,
    required this.catalog,
    required this.learning,
    required this.repository,
    required this.phoneCoach,
    required this.onPersist,
  });

  @override
  State<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends State<TutorChatScreen> {
  final TextEditingController inputController = TextEditingController();
  final List<TutorChatMessage> messages = [];
  late TutorOrchestrator orchestrator;
  AiRoutingMode mode = AiRoutingMode.preferOnDevice;
  bool isGenerating = false;
  String currentStreamText = '';

  @override
  void initState() {
    super.initState();
    inputController.text = widget.initialPrompt ?? '';
    final fallback = DeterministicTutorFallback();
    final validator = TutorOutputValidator(repository: widget.repository);
    final cloudProvider = SumiCloudTutorProvider();

    orchestrator = TutorOrchestrator(
      phoneCoach: widget.phoneCoach,
      cloudProvider: cloudProvider,
      fallback: fallback,
      validator: validator,
    );

    // Initial greeting message
    final initialFallback = fallback.generateFallback(
      catalog: widget.catalog,
      state: widget.learning,
      prompt: 'hello',
    );

    messages.add(
      TutorChatMessage(
        id: 'm_init',
        text: initialFallback.answer,
        isUser: false,
        providerType: TutorProviderType.fallback,
        modelName: 'Authored Guidance',
      ),
    );
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || isGenerating) return;
    final userText = text.trim();
    inputController.clear();

    setState(() {
      messages.add(
        TutorChatMessage(
          id: 'm_${DateTime.now().microsecondsSinceEpoch}',
          text: userText,
          isUser: true,
        ),
      );
      isGenerating = true;
      currentStreamText = '';
    });

    try {
      final response = await orchestrator.queryTutor(
        catalog: widget.catalog,
        state: widget.learning,
        prompt: userText,
        mode: mode,
        // TUT-02: consent lives in settings; cloud is not configured (TUT-03)
        // and the local routes below never send anything off the device.
        cloudConsentGiven: widget.learning.settings.cloudConsent,
        onStreamChunk: (chunk) {
          setState(() {
            currentStreamText = chunk;
          });
        },
      );

      if (mounted) {
        setState(() {
          messages.add(
            TutorChatMessage(
              id: 'm_${DateTime.now().microsecondsSinceEpoch}',
              text: response.answer,
              isUser: false,
              providerType: response.providerType,
              modelName: response.modelIdentifier,
            ),
          );
          isGenerating = false;
          currentStreamText = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          messages.add(
            TutorChatMessage(
              id: 'm_err_${DateTime.now().microsecondsSinceEpoch}',
              text: e is CloudNotConfigured
                  ? 'Cloud AI is not configured. Lessons and on-device help still work.'
                  : 'The tutor couldn’t answer just now. Your lesson is unaffected — try again.',
              isUser: false,
              providerType: TutorProviderType.fallback,
              modelName: 'Authored Guidance',
            ),
          );
          isGenerating = false;
          currentStreamText = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: SumiColors.canvas,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sumi Tutor · ${widget.catalog.title}', style: t.titleMedium),
            Text(
              'Goal: ${widget.learning.goal.isEmpty ? "Learning path" : widget.learning.goal}',
              style: t.bodySmall,
            ),
          ],
        ),
        actions: [
          DropdownButton<AiRoutingMode>(
            value: mode,
            underline: SizedBox(),
            items: const [
              DropdownMenuItem(
                value: AiRoutingMode.preferOnDevice,
                child: Text('Prefer On-Device', style: TextStyle(fontSize: 12)),
              ),
              DropdownMenuItem(
                value: AiRoutingMode.onDeviceOnly,
                child: Text('On-Device Only', style: TextStyle(fontSize: 12)),
              ),
              DropdownMenuItem(
                value: AiRoutingMode.cloudOff,
                child: Text('Cloud off (not configured)', style: TextStyle(fontSize: 12)),
              ),
            ],
            onChanged: (m) {
              if (m != null) setState(() => mode = m);
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: messages.length + (isGenerating ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && isGenerating) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Surface(
                          color: Color(0xFFF0F4F8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: SumiColors.primary,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  currentStreamText.isEmpty
                                      ? 'Generating tutor response…'
                                      : currentStreamText,
                                  style: t.bodyMedium,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  widget.phoneCoach.cancel();
                                  setState(() => isGenerating = false);
                                },
                                child: Text('Stop'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final m = messages[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Align(
                        alignment: m.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 560),
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: m.isUser ? SumiColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: m.isUser
                                ? null
                                : Border.all(color: SumiColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!m.isUser) ...[
                                // TUT-02: the badge always names who answered.
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: providerBadgeFor(
                                    m.providerType,
                                    m.modelName,
                                  ),
                                ),
                                SizedBox(height: 8),
                              ],
                              Text(
                                m.text,
                                style: t.bodyMedium?.copyWith(
                                  color: m.isUser
                                      ? Colors.white
                                      : SumiColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Suggested Follow-Up Chips
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Color(0xFFF9FAFC),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        label: Text('Explain in simpler steps'),
                        onPressed: isGenerating
                            ? null
                            : () => sendMessage('Explain in simpler steps'),
                      ),
                      SizedBox(width: 8),
                      ActionChip(
                        label: Text('Give another small example'),
                        onPressed: isGenerating
                            ? null
                            : () => sendMessage('Give another small example'),
                      ),
                      SizedBox(width: 8),
                      ActionChip(
                        label: Text('How does this connect to my goal?'),
                        onPressed: isGenerating
                            ? null
                            : () => sendMessage(
                                'How does this connect to my goal?',
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // Input field
              SafeArea(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: SumiColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: inputController,
                          decoration: InputDecoration(
                            hintText: 'Ask Sumi tutor a contextual follow-up…',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: isGenerating
                              ? null
                              : (val) => sendMessage(val),
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                          color: SumiColors.primary,
                        ),
                        onPressed: isGenerating
                            ? null
                            : () => sendMessage(inputController.text),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// TUT-02 (DC §7.38): the badge matches the responder.
ProviderBadge providerBadgeFor(TutorProviderType type, String model) =>
    switch (type) {
      TutorProviderType.local => ProviderBadge.onDevice(model),
      TutorProviderType.cloud => ProviderBadge(
        text: 'CLOUD · ${model.toUpperCase()}',
        icon: Icons.cloud_rounded,
      ),
      TutorProviderType.fallback => ProviderBadge.authored(),
    };
