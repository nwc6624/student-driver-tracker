import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> requestAllPermissions() async {
    final location = await requestLocationPermission();
    final storage = await requestStoragePermission();
    return location && storage;
  }
}
