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

  Future<GpsFix?> freshFix({
    Duration timeout = const Duration(seconds: 15),
    double acceptableAccuracyMeters = 40,
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 15),
        ),
      ).timeout(timeout);

      if (position.accuracy <= acceptableAccuracyMeters) {
        return _toFix(position);
      }

      try {
        final refined = await Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 0,
          ),
        )
            .where((candidate) => candidate.accuracy <= acceptableAccuracyMeters)
            .timeout(const Duration(seconds: 8))
            .first;
        return _toFix(refined);
      } catch (_) {
        return _toFix(position);
      }
    } catch (_) {
      return null;
    }
  }

  GpsFix _toFix(Position position) {
    return GpsFix(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      manual: false,
    );
  }

  Future<GpsFix?> currentFix({
    Duration timeout = const Duration(seconds: 12),
    bool allowLastKnown = true,
  }) async {
    final fresh = await freshFix(timeout: timeout);
    if (fresh != null) return fresh;
    if (!allowLastKnown) return null;
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
