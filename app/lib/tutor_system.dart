import 'on_device.dart';
import 'models.dart';
import 'resource_system.dart';

enum AiRoutingMode {
  askEveryTime,
  preferOnDevice,
  onDeviceOnly,
  preferCloudSpecialist,
  cloudOff,
}

enum TutorProviderType { local, cloud, fallback }

class TutorContextEnvelope {
  final int schemaVersion;
  final String requestId;
  final String disciplineId;
  final String goalId;
  final String currentCapabilityId;
  final String recentEvidenceSummary;
  final String learnerPreferencesSummary;
  final List<String> approvedResourceIds;
  final String requestedAction;
  final List<String> safetyFlags;
  final int maxTokens;

  TutorContextEnvelope({
    this.schemaVersion = 1,
    required this.requestId,
    required this.disciplineId,
    required this.goalId,
    required this.currentCapabilityId,
    required this.recentEvidenceSummary,
    required this.learnerPreferencesSummary,
    required this.approvedResourceIds,
    required this.requestedAction,
    this.safetyFlags = const [],
    this.maxTokens = 300,
  });

  Json toJson() => {
    'schema_version': schemaVersion,
    'request_id': requestId,
    'discipline_id': disciplineId,
    'goal_id': goalId,
    'current_capability_id': currentCapabilityId,
    'recent_evidence_summary': recentEvidenceSummary,
    'learner_preferences_summary': learnerPreferencesSummary,
    'approved_resource_ids': approvedResourceIds,
    'requested_action': requestedAction,
    'safety_flags': safetyFlags,
    'max_tokens': maxTokens,
  };
}

class TutorResponse {
  final String responseId;
  final TutorProviderType providerType;
  final String modelIdentifier;
  final String answer;
  final String? uncertaintyStatement;
  final List<String> referencedResourceIds;
  final List<String> suggestedFollowUps;

  TutorResponse({
    required this.responseId,
    required this.providerType,
    required this.modelIdentifier,
    required this.answer,
    this.uncertaintyStatement,
    this.referencedResourceIds = const [],
    this.suggestedFollowUps = const [],
  });

  factory TutorResponse.fromJson(Json j) => TutorResponse(
    responseId: j['response_id'] ?? '',
    providerType: TutorProviderType.values.firstWhere(
      (e) => e.name == j['provider_type'],
      orElse: () => TutorProviderType.fallback,
    ),
    modelIdentifier: j['model_identifier'] ?? 'unknown',
    answer: j['answer'] ?? '',
    uncertaintyStatement: j['uncertainty_statement'],
    referencedResourceIds: List<String>.from(
      j['referenced_resource_ids'] ?? [],
    ),
    suggestedFollowUps: List<String>.from(j['suggested_follow_ups'] ?? []),
  );

  Json toJson() => {
    'response_id': responseId,
    'provider_type': providerType.name,
    'model_identifier': modelIdentifier,
    'answer': answer,
    'uncertainty_statement': uncertaintyStatement,
    'referenced_resource_ids': referencedResourceIds,
    'suggested_follow_ups': suggestedFollowUps,
  };
}

class TutorOutputValidator {
  final ResourceRepository repository;

  TutorOutputValidator({required this.repository});

  TutorResponse validateAndSanitize(TutorResponse response) {
    // 1. Validate referenced resource IDs
    final validResourceIds = <String>[];
    for (final id in response.referencedResourceIds) {
      if (repository.getResourceById(id) != null) {
        validResourceIds.add(id);
      }
    }

    // 2. Sanitize any mutative tokens attempting to alter route or grades
    var sanitizedAnswer = response.answer;
    if (sanitizedAnswer.contains('MUTATE_ROUTE') ||
        sanitizedAnswer.contains('GRANT_GRADE') ||
        sanitizedAnswer.contains('AWARD_POINTS')) {
      sanitizedAnswer = sanitizedAnswer
          .replaceAll(RegExp(r'MUTATE_ROUTE|GRANT_GRADE|AWARD_POINTS'), '')
          .trim();
    }

    // 3. Filter suggested follow-ups against allow-list
    const allowList = [
      'Explain in simpler steps',
      'Give another small example',
      'How does this connect to my goal?',
      'Check my understanding',
    ];
    final validFollowUps = response.suggestedFollowUps
        .where((f) => allowList.contains(f))
        .toList();
    if (validFollowUps.isEmpty) {
      validFollowUps.addAll([
        'Explain in simpler steps',
        'Give another small example',
      ]);
    }

    return TutorResponse(
      responseId: response.responseId,
      providerType: response.providerType,
      modelIdentifier: response.modelIdentifier,
      answer: sanitizedAnswer,
      uncertaintyStatement: response.uncertaintyStatement,
      referencedResourceIds: validResourceIds,
      suggestedFollowUps: validFollowUps,
    );
  }
}

class CustomPlanValidator {
  bool validateDraftGraph({
    required List<Json> milestones,
    required List<Resource> canonicalResources,
  }) {
    // 1. Check acyclic prerequisites
    final graph = <String, List<String>>{};
    final allIds = <String>{};

    for (final m in milestones) {
      final id = m['id'] as String;
      allIds.add(id);
      final prereqs = List<String>.from(m['prerequisites'] ?? []);
      graph[id] = prereqs;
    }

    final visited = <String, int>{};
    bool hasCycle(String node) {
      visited[node] = 1;
      for (final p in graph[node] ?? []) {
        if (!allIds.contains(p)) return true; // Missing prerequisite ID
        if (visited[p] == 1) return true; // Cycle detected!
        if (visited[p] == 0 || visited[p] == null) {
          if (hasCycle(p)) return true;
        }
      }
      visited[node] = 2;
      return false;
    }

    for (final id in allIds) {
      if (visited[id] == 0 || visited[id] == null) {
        if (hasCycle(id)) return false;
      }
    }

    // 2. Workload check
    for (final m in milestones) {
      final minutes = m['minutes'] as int? ?? 15;
      if (minutes > 60 || minutes < 5) return false;
    }

    // 3. Safety check
    for (final m in milestones) {
      final text = '${m['title']} ${m['subtitle']} ${m['deliverable']}'
          .toLowerCase();
      if (text.contains('weapons') ||
          text.contains('explosives') ||
          text.contains('illegal drugs')) {
        return false;
      }
    }

    // 4. Resource check (no invented links)
    for (final m in milestones) {
      final resId = m['resource_id'] as String?;
      if (resId != null && resId.contains('example.com')) return false;
    }

    return true;
  }
}

abstract class CloudTutorProviderContract {
  Future<TutorResponse> queryCloud({
    required TutorContextEnvelope envelope,
    required String prompt,
  });
}

/// TUT-03 / CF-03: no cloud provider is configured in this build (owner
/// decision E-04 pending), so no request is ever sent and no cloud text is
/// ever shown. Every call fails with [CloudNotConfigured].
class CloudNotConfigured implements Exception {
  const CloudNotConfigured();
  @override
  String toString() => 'Cloud AI is not configured in this build.';
}

class SumiCloudTutorProvider implements CloudTutorProviderContract {
  final String? backendUrl;
  final String? authToken;

  SumiCloudTutorProvider({this.backendUrl, this.authToken});

  /// Always false: there is no relay implementation to call.
  bool get isConfigured => false;

  @override
  Future<TutorResponse> queryCloud({
    required TutorContextEnvelope envelope,
    required String prompt,
  }) async => throw const CloudNotConfigured();
}

class DeterministicTutorFallback {
  TutorResponse generateFallback({
    required Catalog catalog,
    required LearningState state,
    required String prompt,
  }) {
    final current = state.current(catalog);
    final concept = current?.title ?? catalog.title;
    return TutorResponse(
      responseId: 'res_fallback_${DateTime.now().microsecondsSinceEpoch}',
      providerType: TutorProviderType.fallback,
      modelIdentifier: 'Authored Guidance',
      answer:
          'Based on your goal (${state.goal}) in $concept: Focus on practicing the core step ("${current?.deliverable ?? catalog.project}") and check your results against your baseline.',
      referencedResourceIds: current != null ? [current.resourceId] : [],
      suggestedFollowUps: [
        'Explain in simpler steps',
        'Give another small example',
      ],
    );
  }
}

class TutorOrchestrator {
  final PhoneModelController phoneCoach;
  final CloudTutorProviderContract cloudProvider;
  final DeterministicTutorFallback fallback;
  final TutorOutputValidator validator;

  TutorOrchestrator({
    required this.phoneCoach,
    required this.cloudProvider,
    required this.fallback,
    required this.validator,
  });

  TutorContextEnvelope buildEnvelope({
    required Catalog catalog,
    required LearningState state,
    required String prompt,
    String requestedAction = 'general_coaching',
  }) {
    final current = state.current(catalog);
    final approvedResources = catalog.resources.map((r) => r.id).toList();

    return TutorContextEnvelope(
      requestId: 'req_${DateTime.now().microsecondsSinceEpoch}',
      disciplineId: catalog.id,
      goalId: state.goalRecord?.id ?? 'goal_${catalog.id}',
      currentCapabilityId: current?.id ?? 'general',
      recentEvidenceSummary:
          'Completed ${state.completed.length} milestones, demonstrated ${state.demonstrated.length} capabilities.',
      learnerPreferencesSummary:
          'Daily commitment: ${state.dailyMinutes} min/day.',
      approvedResourceIds: approvedResources,
      requestedAction: requestedAction,
    );
  }

  Future<TutorResponse> queryTutor({
    required Catalog catalog,
    required LearningState state,
    required String prompt,
    required AiRoutingMode mode,
    required bool cloudConsentGiven,
    void Function(String)? onStreamChunk,
  }) async {
    // Check Cloud Off or On-Device Only
    if (mode == AiRoutingMode.cloudOff ||
        mode == AiRoutingMode.onDeviceOnly ||
        mode == AiRoutingMode.preferOnDevice) {
      if (phoneCoach.supported && phoneCoach.installed.isNotEmpty) {
        try {
          final text = await phoneCoach.reply(
            'Discipline: ${catalog.title}. Goal: ${state.goal}. Question: $prompt',
            onText: onStreamChunk,
          );
          final rawResponse = TutorResponse(
            responseId: 'res_local_${DateTime.now().microsecondsSinceEpoch}',
            providerType: TutorProviderType.local,
            modelIdentifier: phoneCoach.activeName ?? 'On-Device GGUF',
            answer: text,
            referencedResourceIds: catalog.resources.map((r) => r.id).toList(),
            suggestedFollowUps: [
              'Explain in simpler steps',
              'Give another small example',
            ],
          );
          return validator.validateAndSanitize(rawResponse);
        } catch (_) {
          // NEVER silently upload to cloud on local failure! Fall back to authored guidance.
          final fallbackResponse = fallback.generateFallback(
            catalog: catalog,
            state: state,
            prompt: prompt,
          );
          return validator.validateAndSanitize(fallbackResponse);
        }
      } else {
        final fallbackResponse = fallback.generateFallback(
          catalog: catalog,
          state: state,
          prompt: prompt,
        );
        return validator.validateAndSanitize(fallbackResponse);
      }
    }

    // Cloud requested or preferred
    if (!cloudConsentGiven) {
      throw StateError(
        'Cloud consent required before sending requests to Cloud AI.',
      );
    }

    try {
      final envelope = buildEnvelope(
        catalog: catalog,
        state: state,
        prompt: prompt,
      );
      final rawResponse = await cloudProvider.queryCloud(
        envelope: envelope,
        prompt: prompt,
      );
      return validator.validateAndSanitize(rawResponse);
    } catch (_) {
      final fallbackResponse = fallback.generateFallback(
        catalog: catalog,
        state: state,
        prompt: prompt,
      );
      return validator.validateAndSanitize(fallbackResponse);
    }
  }
}
