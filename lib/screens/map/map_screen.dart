import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:carlet/models/report_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  final _reportsRef = FirebaseFirestore.instance
      .collection('reports')
      .orderBy('timestamp', descending: true)
      .limit(300);

  Set<Marker> _markers = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _reportsRef.snapshots().listen((snap) {
      final markers = snap.docs.map((d) {
        final r = Report.fromMap(d.id, d.data());
        return Marker(
          markerId: MarkerId(r.id),
          position: LatLng(r.lat, r.lng),
          infoWindow: InfoWindow(
            title: r.licensePlate?.isNotEmpty == true
                ? r.licensePlate
                : 'Reported car',
            snippet: r.message,
          ),
        );
      }).toSet();
      setState(() => _markers = markers);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(0, 0),
        zoom: 1,
      ),
      onMapCreated: (c) => _controller = c,
      markers: _markers,
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      compassEnabled: true,
    );
  }
}
