import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String reporterId;
  final String? photoUrl;
  final String? licensePlate;
  final String? message;
  final String status; // 'open' | 'resolved'
  final DateTime timestamp;
  final DateTime? resolvedAt;
  final DateTime? expireAt;
  final bool anonymous;
  final int likeCount;
  final int commentCount;
  final List<String> likedBy; // User IDs who liked this report

  const Report({
    required this.id,
    required this.reporterId,
    required this.status,
    required this.timestamp,
    this.resolvedAt,
    this.expireAt,
    this.photoUrl,
    this.licensePlate,
    this.message,
    this.anonymous = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedBy = const [],
  });

  factory Report.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate().toUtc();
      if (v is String) return DateTime.tryParse(v)?.toUtc();
      if (v is num) {
        return DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true);
      }
      return null;
    }

    // Parse likedBy list
    List<String> parseLikedBy(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    return Report(
      id: id,
      reporterId: map['reporterId'] as String,
      photoUrl: map['photoUrl'] as String?,
      licensePlate: map['licensePlate'] as String?,
      message: map['message'] as String?,
      status: (map['status'] as String?) ?? 'open',
      // Use parseDate to handle Timestamp, String, numeric epoch, or DateTime.
      timestamp: parseDate(map['timestamp']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      resolvedAt: parseDate(map['resolvedAt']),
      expireAt: parseDate(map['expireAt']),
      anonymous: (map['anonymous'] as bool?) ?? false,
      likeCount: (map['likeCount'] as int?) ?? 0,
      commentCount: (map['commentCount'] as int?) ?? 0,
      likedBy: parseLikedBy(map['likedBy']),
    );
  }
  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'reporterId': reporterId,
      'photoUrl': photoUrl,
      'licensePlate': licensePlate,
      'message': message,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'anonymous': anonymous,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'likedBy': likedBy,
    };
    if (resolvedAt != null) m['resolvedAt'] = Timestamp.fromDate(resolvedAt!);
    if (expireAt != null) m['expireAt'] = Timestamp.fromDate(expireAt!);
    return m;
  }
}
