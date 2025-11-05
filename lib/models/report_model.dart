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
  final bool anonymous;

  const Report({
    required this.id,
    required this.reporterId,
    required this.lat,
    required this.lng,
    required this.status,
    required this.timestamp,
    this.photoUrl,
    this.licensePlate,
    this.message,
    this.anonymous = false,
  });

  Map<String, dynamic> toMap() => {
        'reporterId': reporterId,
        'photoUrl': photoUrl,
        'location': {'lat': lat, 'lng': lng},
        'licensePlate': licensePlate,
        'message': message,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        'anonymous': anonymous,
      };

  factory Report.fromMap(String id, Map<String, dynamic> map) {
    final loc = map['location'] as Map<String, dynamic>?;
    return Report(
      id: id,
      reporterId: map['reporterId'] as String,
      photoUrl: map['photoUrl'] as String?,
      lat: (loc?['lat'] as num).toDouble(),
      lng: (loc?['lng'] as num).toDouble(),
      licensePlate: map['licensePlate'] as String?,
      message: map['message'] as String?,
      status: (map['status'] as String?) ?? 'open',
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(
              (map['timestamp'] is num) ? (map['timestamp'] as num).toInt() : 0,
              isUtc: true),
      anonymous: (map['anonymous'] as bool?) ?? false,
    );
  }
}
