import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import 'package:carlet/models/report_model.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Stream<List<Report>> streamReports({int limit = 200}) {
    return _db
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Report.fromMap(d.id, d.data()))
            .toList(growable: false));
  }

  Future<String?> _uploadPhoto(String reportId, File? file) async {
    if (file == null) return null;
    final ref = _storage.ref().child('reports/$reportId.jpg');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<String> createReport({
    required String reporterId,
    required double lat,
    required double lng,
    String? licensePlate,
    String? message,
    File? photoFile,
    bool anonymous = false,
  }) async {
    final id = _uuid.v4();

    String? photoUrl;
    if (photoFile != null) {
      photoUrl = await _uploadPhoto(id, photoFile);
    }

    final data = Report(
      id: id,
      reporterId: reporterId,
      photoUrl: photoUrl,
      lat: lat,
      lng: lng,
      licensePlate: licensePlate?.toUpperCase().replaceAll(' ', ''),
      message: message,
      status: 'open',
      timestamp: DateTime.now().toUtc(),
      anonymous: anonymous,
    ).toMap();

    await _db.collection('reports').doc(id).set(data);
    return id;
  }

  Future<void> markResolved(String reportId) async {
    await _db
        .collection('reports')
        .doc(reportId)
        .update({'status': 'resolved'});
  }
}
