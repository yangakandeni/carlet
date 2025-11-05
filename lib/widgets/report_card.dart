import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:carlet/models/report_model.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final double? myLat;
  final double? myLng;
  final VoidCallback? onResolve;

  const ReportCard({
    super.key,
    required this.report,
    this.myLat,
    this.myLng,
    this.onResolve,
  });

  String _distanceText() {
    if (myLat == null || myLng == null) return '';
    final meters =
        Geolocator.distanceBetween(myLat!, myLng!, report.lat, report.lng);
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m away';
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.photoUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(report.photoUrl!, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (report.licensePlate != null &&
                        report.licensePlate!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          report.licensePlate!,
                          style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      report.status.toUpperCase(),
                      style: TextStyle(
                        color: report.status == 'open'
                            ? theme.colorScheme.error
                            : theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if ((report.message ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(report.message!),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(_distanceText()),
                    const Spacer(),
                    Text(
                      report.timestamp.toLocal().toString(),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(report.lat, report.lng),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId(report.id),
                          position: LatLng(report.lat, report.lng),
                        ),
                      },
                      zoomControlsEnabled: false,
                      liteModeEnabled: true,
                      myLocationButtonEnabled: false,
                      compassEnabled: false,
                      onMapCreated: (c) {},
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (onResolve != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: onResolve,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark resolved'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
