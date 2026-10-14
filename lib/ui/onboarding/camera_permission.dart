import 'package:permission_handler/permission_handler.dart';

/// Camera permission state, as the QR screen needs it.
enum CameraAccess { granted, denied, permanentlyDenied }

/// Ported from the Kotlin `PermissionRequester.kt`, behind an interface so the
/// QR screen can be tested without a real device permission system.
abstract interface class CameraPermission {
  Future<CameraAccess> check();
  Future<CameraAccess> request();
  Future<void> openSettings();
}

/// The real implementation, using the `permission_handler` package.
///
/// Any platform error (for example in a widget test, where the plugin is not
/// available) is treated as "denied", so the screen falls back to its
/// permission gate and the "enter manually" path instead of crashing.
class DeviceCameraPermission implements CameraPermission {
  const DeviceCameraPermission();

  CameraAccess _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return CameraAccess.granted;
    if (status.isPermanentlyDenied) return CameraAccess.permanentlyDenied;
    return CameraAccess.denied;
  }

  @override
  Future<CameraAccess> check() async {
    try {
      return _map(await Permission.camera.status);
    } catch (_) {
      return CameraAccess.denied;
    }
  }

  @override
  Future<CameraAccess> request() async {
    try {
      return _map(await Permission.camera.request());
    } catch (_) {
      return CameraAccess.denied;
    }
  }

  @override
  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (_) {
      // Nothing more to do; the user can still enter the ID manually.
    }
  }
}

/// A permission that always reports the same answer. For tests, which have no
/// real permission system.
class FixedCameraPermission implements CameraPermission {
  const FixedCameraPermission(this.access);

  final CameraAccess access;

  @override
  Future<CameraAccess> check() async => access;

  @override
  Future<CameraAccess> request() async => access;

  @override
  Future<void> openSettings() async {}
}
