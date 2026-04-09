import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../tracker_constants.dart';

class TrackerLocationService {
  StreamSubscription<Position>? _positionSubscription;

  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Stream<Position> getPositionStream({
    int distanceFilter = 10,
    Duration interval = TrackerConstants.locationInterval,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
        intervalDuration: interval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Location Sharing',
          notificationText: 'Location sharing is active',
          enableWakeLock: true,
        ),
      ),
    );
  }

  void stopListening() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
