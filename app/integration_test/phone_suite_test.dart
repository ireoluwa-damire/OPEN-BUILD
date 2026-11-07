import 'package:integration_test/integration_test.dart';
import '../test/evidence_test.dart' as evidence;
import '../test/refinements_test.dart' as refinements;
import '../test/widget_test.dart' as assessment;
import '../test/discipline_flow_test.dart' as flow;
import 'on_device_test.dart' as model;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  evidence.main();
  refinements.main();
  assessment.main();
  flow.main();
  model.main();
}
