/// Exact onboarding copy (DC §11.1). Tests compare rendered text with these.
abstract final class OnboardingCopy {
  static const promiseTitle =
      'Learn anything by doing it, one clear step at a time.';
  static const promiseSupport = 'A route that adapts to what you can show.';
  static const promiseCta = 'GET STARTED';
  static const promiseResume = 'CONTINUE MY PROGRESS';
  static const cta = 'CONTINUE';

  static const disciplineHeading = 'What do you want to learn?';
  static const customTitle = 'Something else';
  static const customSubtitle = 'Describe any skill or project.';
  static const customSheetLabel =
      'Describe the skill or project you want to learn';

  /// Track subtitles (DC §11.1); unknown tracks use their description.
  static const disciplineSubtitles = {
    'music': 'Rhythm, pitch, practice, and creation.',
    'fashion': 'Design, measure, construct, and refine.',
  };

  static const outcomeHeading = 'What would you like to be able to do?';
  static const outcomeHelper =
      'Describe one thing you want to be able to do (20–200 characters).';
  static const deadlines = [
    'None',
    '2 weeks',
    '1 month',
    '3 months',
    'Custom date',
  ];
  static const constraints = [
    'Phone only',
    'Low bandwidth',
    'No equipment',
    'Beginner materials',
    'Accessibility need',
    'Other',
  ];

  static const motivationHeading = 'Why does this goal matter to you?';
  static const motivations = [
    'Finish a real project.',
    'Support my education.',
    'Improve my career.',
    'Spend time productively.',
    'Express myself creatively.',
    'Build a lasting habit.',
    'Just for fun.',
    'Something else.',
  ];
  static const motivationSupport = {
    'Finish a real project.': 'We’ll keep each task connected to your project.',
    'Support my education.': 'We’ll connect each step to what you’re studying.',
    'Improve my career.': 'We’ll favour skills you can show to others.',
    'Spend time productively.': 'Short, focused steps that fit your day.',
    'Express myself creatively.': 'Every unit ends with something you make.',
    'Build a lasting habit.':
        'Small daily steps, with reviews at the right time.',
    'Just for fun.': 'We’ll keep it light and hands-on.',
    'Something else.': 'We’ll adapt as we learn what helps you.',
  };

  static const levelHeading = 'How much experience do you have with this?';
  static const levels = [
    'I’m completely new.',
    'I know a few terms or basic ideas.',
    'I can complete simple tasks with guidance.',
    'I can work independently on familiar tasks.',
    'I can handle varied tasks and explain my choices.',
  ];

  static const previewHeading = 'Here’s what your route will help you do.';
  static List<String> previewGeneric(String outcome) => [
    'Understand the essential ideas for $outcome.',
    'Complete a small project or performance you can show.',
    'Build a repeatable practice and review habit.',
  ];

  static const goalHeading = 'What’s your daily learning goal?';
  static const goalLabels = {
    5: 'Casual',
    10: 'Regular',
    15: 'Serious',
    20: 'Intense',
  };
  static String workload(int m, int a, int b) =>
      'At $m minutes a day, the first project is roughly $a–$b sessions.';

  static const routeHeading = 'Let’s find the best place to start.';
  static const routeBasicsTitle = 'Start from the basics';
  static const routeBasicsBody =
      'Begin with the first foundation and still answer a few light checks.';
  static const routeLevelTitle = 'Find my level';
  static const routeLevelBody =
      'Try a short baseline so Sumi can recommend a starting point.';

  static const baselineHeading = 'A short starting check';
  static const baselineBody =
      'Six quick questions. Your first answer is kept, hints are fine, and you can say “I don’t know yet”. No score is shown.';
  static const baselineCta = 'START THE CHECK';
  static const baselineResume = 'CONTINUE THE CHECK';

  static const revealHeading = 'Your first route is ready.';
  static String revealEvidence(int n) => 'Based on $n starting checks';
  static const revealChoice = 'Based on your starting choice';
  static const revealWhy = 'Why this route?';
  static const revealCta = 'START FIRST LESSON';
}
