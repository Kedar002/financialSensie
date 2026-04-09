import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_data.dart';

class TrackerFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Write location data for a tracking device
  Future<void> updateLocation(String deviceId, LocationData data) async {
    await _firestore.collection('locations').doc(deviceId).set(data.toMap());

    // Also add to history subcollection
    await _firestore
        .collection('location_history')
        .doc(deviceId)
        .collection('points')
        .add(data.toMap());
  }

  // Listen to real-time location updates for a paired device
  Stream<LocationData?> locationStream(String deviceId) {
    return _firestore
        .collection('locations')
        .doc(deviceId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return LocationData.fromMap(snapshot.data()!);
    });
  }

  // Get latest location once
  Future<LocationData?> getLatestLocation(String deviceId) async {
    final doc = await _firestore.collection('locations').doc(deviceId).get();
    if (!doc.exists || doc.data() == null) return null;
    return LocationData.fromMap(doc.data()!);
  }

  // Get location history
  Stream<List<LocationData>> locationHistory(String deviceId, {int limit = 100}) {
    return _firestore
        .collection('location_history')
        .doc(deviceId)
        .collection('points')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationData.fromMap(doc.data()))
            .toList());
  }

  // Register a device with a pairing code
  Future<void> registerDevice(String code, String deviceId, String role) async {
    await _firestore.collection('devices').doc(code).set({
      'deviceId': deviceId,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Look up a device by pairing code
  Future<String?> lookupDevice(String code) async {
    final doc = await _firestore.collection('devices').doc(code).get();
    if (!doc.exists || doc.data() == null) return null;
    return doc.data()!['deviceId'] as String?;
  }

  // Delete all location history for a device
  Future<void> deleteAllHistory(String deviceId) async {
    final collection = _firestore
        .collection('location_history')
        .doc(deviceId)
        .collection('points');

    var batch = _firestore.batch();
    var count = 0;

    final snapshots = await collection.get();
    for (final doc in snapshots.docs) {
      batch.delete(doc.reference);
      count++;
      if (count >= 500) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }

  // Delete history older than a given date
  Future<void> deleteHistoryOlderThan(String deviceId, DateTime cutoff) async {
    final collection = _firestore
        .collection('location_history')
        .doc(deviceId)
        .collection('points');

    final snapshots = await collection
        .where('timestamp', isLessThan: Timestamp.fromDate(cutoff))
        .get();

    var batch = _firestore.batch();
    var count = 0;

    for (final doc in snapshots.docs) {
      batch.delete(doc.reference);
      count++;
      if (count >= 500) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }

  // Save update frequency preference
  Future<void> setUpdateFrequency(String deviceId, String frequency) async {
    await _firestore.collection('preferences').doc(deviceId).set({
      'updateFrequency': frequency,
    }, SetOptions(merge: true));
  }
}
