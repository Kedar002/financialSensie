import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../core/models/location_data.dart';
import '../core/models/saved_location.dart';
import '../core/models/tracker_settings.dart';
import '../core/services/firebase_service.dart';
import '../core/repositories/saved_location_repository.dart';
import '../widgets/location_detail_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TrackerFirebaseService _firebaseService = TrackerFirebaseService();
  final SavedLocationRepository _savedRepo = SavedLocationRepository();
  String? _deviceId;
  TrackerSettings _settings = const TrackerSettings();
  int _tabIndex = 0; // 0 = Recent, 1 = Saved
  List<SavedLocation> _savedLocations = [];
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = await TrackerSettings.load();
    final saved = await _savedRepo.getAll();
    if (mounted) {
      setState(() {
        _deviceId = prefs.getString('tracker_paired_device_id');
        _settings = settings;
        _savedLocations = saved;
      });
    }

    // Auto-delete old history if enabled
    if (settings.autoDeleteHistory && _deviceId != null) {
      final cutoff = DateTime.now().subtract(const Duration(days: 15));
      await _firebaseService.deleteHistoryOlderThan(_deviceId!, cutoff);
    }
  }

  Future<void> _refreshSaved() async {
    final saved = await _savedRepo.getAll();
    if (mounted) setState(() => _savedLocations = saved);
  }

  Future<void> _saveLocation(LocationData loc) async {
    await _savedRepo.save(loc);
    await _refreshSaved();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location saved'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteSavedLocation(int id) async {
    await _savedRepo.delete(id);
    await _refreshSaved();
  }

  Future<void> _deleteAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete All History',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: const Text(
          'This will permanently delete all location history from the server. This cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF888888),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && _deviceId != null) {
      setState(() => _isDeleting = true);
      await _firebaseService.deleteAllHistory(_deviceId!);
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('History deleted'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDetail(LocationData data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationDetailSheet(
        location: data,
        useKm: _settings.useKm,
      ),
    );
  }

  void _showSavedDetail(SavedLocation data) {
    // Convert to LocationData for the detail sheet
    final loc = LocationData(
      latitude: data.latitude,
      longitude: data.longitude,
      timestamp: data.timestamp,
      speed: data.speed,
      heading: data.heading,
      accuracy: data.accuracy,
      batteryLevel: data.batteryLevel,
      isCharging: data.isCharging,
    );
    _showDetail(loc);
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  String _formatDate(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);

    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM d, y').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            children: [
              const Text(
                'History',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              if (_tabIndex == 0 && _deviceId != null)
                GestureDetector(
                  onTap: _isDeleting ? null : _deleteAllHistory,
                  child: _isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE53935),
                          ),
                        )
                      : const Icon(
                          Icons.delete_outline,
                          size: 22,
                          color: Color(0xFF888888),
                        ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Segmented control
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _SegmentTab(
                  label: 'Recent',
                  isSelected: _tabIndex == 0,
                  onTap: () => setState(() => _tabIndex = 0),
                ),
                _SegmentTab(
                  label: 'Saved',
                  isSelected: _tabIndex == 1,
                  onTap: () {
                    setState(() => _tabIndex = 1);
                    _refreshSaved();
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Content
        Expanded(
          child: _tabIndex == 0 ? _buildRecentTab() : _buildSavedTab(),
        ),
      ],
    );
  }

  Widget _buildRecentTab() {
    if (_deviceId == null) {
      return const Center(
        child: Text(
          'No device paired',
          style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
        ),
      );
    }

    return StreamBuilder<List<LocationData>>(
      stream: _firebaseService.locationHistory(_deviceId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.black,
            ),
          );
        }

        final locations = snapshot.data ?? [];
        if (locations.isEmpty) {
          return const Center(
            child: Text(
              'No history yet',
              style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
            ),
          );
        }

        final grouped = <String, List<LocationData>>{};
        for (final loc in locations) {
          final key = _formatDate(loc.timestamp);
          grouped.putIfAbsent(key, () => []).add(loc);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final date = grouped.keys.elementAt(index);
            final items = grouped[date]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index > 0) const SizedBox(height: 24),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map((loc) => _RecentHistoryItem(
                      location: loc,
                      time: _formatTime(loc.timestamp),
                      onTap: () => _showDetail(loc),
                      onSave: () => _saveLocation(loc),
                    )),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSavedTab() {
    if (_savedLocations.isEmpty) {
      return const Center(
        child: Text(
          'No saved locations',
          style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
        ),
      );
    }

    final grouped = <String, List<SavedLocation>>{};
    for (final loc in _savedLocations) {
      final key = _formatDate(loc.timestamp);
      grouped.putIfAbsent(key, () => []).add(loc);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final date = grouped.keys.elementAt(index);
        final items = grouped[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 24),
            Text(
              date,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF888888),
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((loc) => _SavedHistoryItem(
                  location: loc,
                  time: _formatTime(loc.timestamp),
                  onTap: () => _showSavedDetail(loc),
                  onDelete: () => _deleteSavedLocation(loc.id!),
                )),
          ],
        );
      },
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.black : const Color(0xFF888888),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentHistoryItem extends StatelessWidget {
  final LocationData location;
  final String time;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const _RecentHistoryItem({
    required this.location,
    required this.time,
    required this.onTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '±${location.accuracy.toStringAsFixed(0)}m • ${location.speedKmh.toStringAsFixed(1)} km/h',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onSave,
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.bookmark_outline,
                  size: 18,
                  color: Color(0xFFCCCCCC),
                ),
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedHistoryItem extends StatelessWidget {
  final SavedLocation location;
  final String time;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedHistoryItem({
    required this.location,
    required this.time,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '±${location.accuracy.toStringAsFixed(0)}m • ${location.speedKmh.toStringAsFixed(1)} km/h',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Color(0xFFCCCCCC),
                ),
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
