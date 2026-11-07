import 'package:flutter/foundation.dart';

import '../models.dart';

/// The active learner's settings (SET-05, SND-01/02). The shell publishes a
/// copy after every commit so the theme, text size, sound and haptics follow
/// the saved values without a restart.
final ValueNotifier<LearnerSettings> appSettings = ValueNotifier(
  LearnerSettings(),
);
