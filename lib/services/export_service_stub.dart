// lib/services/export_service_stub.dart
//
// Mobile/desktop implementation stub.
// Used on non-web builds — provides path_provider access.
// The web build uses export_service_web.dart instead.
import 'package:path_provider/path_provider.dart';

/// Returns the app's documents directory on mobile/desktop.
Future<dynamic> getAppDocumentsDirectory() async {
  return await getApplicationDocumentsDirectory();
}

/// Stub — not used on mobile (browser download not available).
void downloadFileWeb(String fileName, String content) {
  throw UnsupportedError('Browser download not supported on mobile.');
}
