import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GpsFix {
  const GpsFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.manual,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final bool manual;
}

enum LocationPermissionOutcome { granted, denied, permanentlyDenied, disabled }

class LocationService {
  static const rationale =
      'A.R.I.D. tags each breeding-site photo with GPS so your map stays '
      'accurate even without internet. Location is stored on this device first '
      'and only synced later.';

  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<bool> isWhenInUseGranted() async {
    return Permission.locationWhenInUse.status.isGranted;
  }

  Future<LocationPermissionOutcome> requestPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
    }
    if (status.isPermanentlyDenied) {
      return LocationPermissionOutcome.permanentlyDenied;
    }
    if (!status.isGranted) return LocationPermissionOutcome.denied;

    final serviceOn = await isServiceEnabled();
    if (!serviceOn) return LocationPermissionOutcome.disabled;
    return LocationPermissionOutcome.granted;
  }

  Future<GpsFix?> currentFix({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      ).timeout(timeout);
      return GpsFix(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        manual: false,
      );
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) return null;
        return GpsFix(
          latitude: last.latitude,
          longitude: last.longitude,
          accuracy: last.accuracy,
          manual: false,
        );
      } catch (_) {
        return null;
      }
    }
  }
}
