import 'package:flutter/material.dart';
import 'package:pulse_ev/config/app_theme.dart';

class PulseMap extends StatelessWidget {
  final List<String> markers; // Simple marker labels for mock

  const PulseMap({
    super.key,
    this.markers = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.background,
      child: Stack(
        children: [
          // Mock Map Background
          Center(
            child: Icon(
              Icons.map_outlined,
              size: 100,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          // Mock Markers
          ...markers.asMap().entries.map((entry) {
            return Positioned(
              left: 50.0 + (entry.key * 40),
              top: 100.0 + (entry.key * 60),
              child: const Icon(
                Icons.location_on,
                color: AppColors.emergency,
                size: 32,
              ),
            );
          }),
        ],
      ),
    );
  }
}
