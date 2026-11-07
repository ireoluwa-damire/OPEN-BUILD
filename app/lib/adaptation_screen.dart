import 'package:flutter/material.dart';
import 'adaptation_system.dart';
import 'theme.dart';
import 'widgets.dart';

class AdaptationScreen extends StatefulWidget {
  /// Read on every build: a committed transaction replaces the profile object.
  final LearnerAdaptationProfile Function() profile;

  /// One explicit-preference change through a transaction (ARC-01).
  final Future<void> Function(void Function(LearnerAdaptationProfile p) change)
  onUpdate;
  final Future<void> Function() onResetInferred;

  const AdaptationScreen({
    super.key,
    required this.profile,
    required this.onUpdate,
    required this.onResetInferred,
  });

  @override
  State<AdaptationScreen> createState() => _AdaptationScreenState();
}

class _AdaptationScreenState extends State<AdaptationScreen> {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = widget.profile();
    final observations = p.inferredObservations.values.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: SumiColors.canvas,
        title: Text('How Sumi is Adapting', style: t.titleMedium),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: EdgeInsets.all(24),
            children: [
              Surface(
                color: SumiColors.primarySoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_rounded,
                          color: SumiColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'EVIDENCE-BASED ADAPTATION',
                          style: t.labelSmall?.copyWith(
                            color: SumiColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sumi adapts based on observable checks and your explicit settings. Sumi never uses fixed talent labels or learning style categories.',
                      style: t.bodyMedium,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Text('Inferred Observations', style: t.titleLarge),
              SizedBox(height: 6),
              Text(
                'Preliminary observations from your recent learning checks:',
                style: t.bodySmall,
              ),
              SizedBox(height: 12),

              if (observations.isEmpty)
                Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No strong inferred patterns yet.',
                        style: t.titleMedium,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sumi requires at least 3 comparable checks before inferring a soft preference.',
                        style: t.bodySmall,
                      ),
                    ],
                  ),
                )
              else
                for (final obs in observations)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Surface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Tag(
                                obs.confidence >= 0.8
                                    ? 'CONFIDENT'
                                    : 'PRELIMINARY OBSERVED',
                                background: Color(0xFFE2F5EC),
                              ),
                              Spacer(),
                              Text(
                                'Evidence: ${obs.evidenceCount} checks',
                                style: t.bodySmall,
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(obs.description, style: t.titleMedium),
                          SizedBox(height: 4),
                          Text(
                            'Effect on sessions: ${obs.effectDescription}',
                            style: t.bodyMedium,
                          ),
                          SizedBox(height: 8),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(
                              'Trace Event IDs (${obs.sourceEventIds.length})',
                              style: t.bodySmall?.copyWith(
                                color: SumiColors.primary,
                              ),
                            ),
                            children: [
                              for (final id in obs.sourceEventIds)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 2),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      id,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        color: SumiColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

              SizedBox(height: 24),
              Text('Your Explicit Overrides', style: t.titleLarge),
              SizedBox(height: 12),
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Preferred Resource Format'),
                      subtitle: Text(
                        'Overrides inferred video/article soft rankings',
                      ),
                      trailing: DropdownButton<String?>(
                        value: p.explicitFormatPreference,
                        hint: Text('Auto (Evidence)'),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Auto (Evidence)'),
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
                            (p) => p.explicitFormatPreference = val,
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                    Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Explanation Approach'),
                      subtitle: Text('Preferred explanation structure'),
                      trailing: DropdownButton<String?>(
                        value: p.explicitExplanationStyle,
                        hint: Text('Standard'),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Standard'),
                          ),
                          DropdownMenuItem(
                            value: 'example_first',
                            child: Text('Example-first'),
                          ),
                          DropdownMenuItem(
                            value: 'concise',
                            child: Text('Concise steps'),
                          ),
                        ],
                        onChanged: (val) async {
                          await widget.onUpdate(
                            (p) => p.explicitExplanationStyle = val,
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.red.shade300),
                ),
                onPressed: () async {
                  await widget.onResetInferred();
                  if (!context.mounted) return;
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Inferred observations reset. Learning progress and accessibility settings preserved.',
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.refresh_rounded, color: Colors.red),
                label: Text(
                  'Reset Inferred Observations',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
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
