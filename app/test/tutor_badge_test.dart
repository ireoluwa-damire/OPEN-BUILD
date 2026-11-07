import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/tutor_chat_screen.dart';
import 'package:sumi/tutor_system.dart';

/// TUT-02: every response carries a badge naming the real responder.
void main() {
  test('badge text matches the provider type', () {
    expect(providerBadgeFor(TutorProviderType.fallback, 'Authored Guidance').text, 'AUTHORED');
    expect(providerBadgeFor(TutorProviderType.local, 'Qwen3 0.6B').text, 'ON-DEVICE · QWEN3 0.6B');
    expect(providerBadgeFor(TutorProviderType.cloud, 'relay').text, startsWith('CLOUD · '));
  });
}
