import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String reporterId;
  final String? photoUrl;
  final double lat;
  final double lng;
  final String? licensePlate;
  final String? message;
  final String status; // 'open' | 'resolved'
  final DateTime timestamp;
  final DateTime? resolvedAt;
  final DateTime? expireAt;
  final bool anonymous;

  const Report({
    required this.id,
    required this.reporterId,
    required this.lat,
    required this.lng,
    required this.status,
    required this.timestamp,
    this.resolvedAt,
    this.expireAt,
    this.photoUrl,
    this.licensePlate,
    this.message,
    this.anonymous = false,
  });
  

  factory Report.fromMap(String id, Map<String, dynamic> map) {
    final loc = map['location'] as Map<String, dynamic>?;
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate().toUtc();
      if (v is String) return DateTime.tryParse(v)?.toUtc();
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true);
      return null;
    }

    return Report(
      id: id,
      reporterId: map['reporterId'] as String,
      photoUrl: map['photoUrl'] as String?,
      lat: (loc?['lat'] as num).toDouble(),
      lng: (loc?['lng'] as num).toDouble(),
      licensePlate: map['licensePlate'] as String?,
      message: map['message'] as String?,
      status: (map['status'] as String?) ?? 'open',
      // Use parseDate to handle Timestamp, String, numeric epoch, or DateTime.
      timestamp: parseDate(map['timestamp']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      resolvedAt: parseDate(map['resolvedAt']),
      expireAt: parseDate(map['expireAt']),
      anonymous: (map['anonymous'] as bool?) ?? false,
    );
  }
  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'reporterId': reporterId,
      'photoUrl': photoUrl,
      'location': {'lat': lat, 'lng': lng},
      'licensePlate': licensePlate,
      'message': message,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'anonymous': anonymous,
    };
    if (resolvedAt != null) m['resolvedAt'] = resolvedAt!.toIso8601String();
    if (expireAt != null) m['expireAt'] = expireAt!.toIso8601String();
    return m;
  }
}
