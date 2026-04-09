import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/offline_location.dart';
import '../repositories/offline_location_repository.dart';

class TrackerSyncService {
  final OfflineLocationRepository _repo = OfflineLocationRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> syncPending(String deviceId) async {
    final pending = await _repo.getPending();
    if (pending.isEmpty) return 0;

    int synced = 0;
    for (final loc in pending) {
      try {
        final data = {
          'latitude': loc.latitude,
          'longitude': loc.longitude,
          'timestamp': Timestamp.fromDate(loc.timestamp),
          'speed': loc.speed,
          'heading': loc.heading,
          'accuracy': loc.accuracy,
          'batteryLevel': loc.batteryLevel,
          'isCharging': loc.isCharging,
        };

        await _firestore.collection('locations').doc(deviceId).set(data);
        await _firestore
            .collection('location_history')
            .doc(deviceId)
            .collection('points')
            .add(data);

        await _repo.delete(loc.id!);
        synced++;
      } catch (_) {
        break; // Stop syncing on first failure
      }
    }
    return synced;
  }

  Future<void> enqueue({
    required double latitude,
    required double longitude,
    required double accuracy,
    required double speed,
    required double heading,
    required int batteryLevel,
    required bool isCharging,
  }) async {
    await _repo.enqueue(OfflineLocation(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      speed: speed,
      heading: heading,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      timestamp: DateTime.now(),
      createdAt: DateTime.now(),
    ));
  }
}
