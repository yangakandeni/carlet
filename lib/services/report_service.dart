import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import 'package:carlet/models/report_model.dart';
import 'package:carlet/services/comment_service.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Get storage instance dynamically to ensure emulator connection is respected
  FirebaseStorage get _storage => FirebaseStorage.instance;
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final _uuid = const Uuid();
  final _commentService = CommentService();

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
    // Use refFromURL for emulators or ref() for production
    final ref = _storage.ref('reports/$reportId/photo.jpg');

    // Attach content-type metadata so Storage security rules that require
    // image/* content types will allow the upload.
    String contentType = 'image/jpeg';
    final lower = file.path.toLowerCase();
    if (lower.endsWith('.png')) {
      contentType = 'image/png';
    } else if (lower.endsWith('.gif'))
      contentType = 'image/gif';
    else if (lower.endsWith('.webp')) contentType = 'image/webp';

    final metadata = SettableMetadata(contentType: contentType);
    final task = await ref.putFile(file, metadata);
    return await task.ref.getDownloadURL();
  }

  Future<String> createReport({
    required String reporterId,
    String? licensePlate,
    String? message,
    File? photoFile,
    bool anonymous = false,
  }) async {
    // Verify user is authenticated before attempting upload
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to create a report');
    }

    // Force token refresh to ensure auth is valid
    await currentUser.getIdToken(true);

    final id = _uuid.v4();

    String? photoUrl;
    if (photoFile != null) {
      photoUrl = await _uploadPhoto(id, photoFile);
    }

    final data = Report(
      id: id,
      reporterId: reporterId,
      photoUrl: photoUrl,
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
    final docRef = _db.collection('reports').doc(reportId);
    final now = DateTime.now().toUtc();
    // Set status to resolved and add timestamps so a backend TTL policy or
    // Cloud Function can remove the document after 30 minutes. Firestore now
    // supports TTL policies configured in the console; set `expireAt` to the
    // desired deletion time to enable TTL deletion if configured.
    await docRef.update({
      'status': 'resolved',
      'resolvedAt': Timestamp.fromDate(now),
      'expireAt': Timestamp.fromDate(now.add(const Duration(minutes: 30))),
    });

    // Delete all comments when report is resolved
    await _commentService.deleteCommentsForReport(reportId);
  }
}
