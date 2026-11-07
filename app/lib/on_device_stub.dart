import 'package:flutter/foundation.dart';
import 'phone_model_types.dart';
import 'models.dart';

class PhoneModelController extends ChangeNotifier {
  bool get supported => false;
  bool get busy => false;
  bool get generating => false;
  bool get initialized => true;
  String get status =>
      'Model downloads and offline inference run in the installed mobile app.';
  double? get progress => null;
  String? get workingId => null;
  String? get activeId => null;
  String? get activeName => null;
  List<PhoneModelChoice> get choices => [];
  List<Json> get installed => [];
  Json get device => {};
  Future<void> initialize() async {}
  Future<void> download(PhoneModelChoice choice) async {}
  Future<void> select(String id) async {}
  Future<void> remove(String id) async {}
  Future<void> importModel() async {}
  void cancel() {}
  Future<String> reply(String prompt, {void Function(String)? onText}) async =>
      throw UnsupportedError(status);
}
