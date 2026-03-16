import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_card.dart';

class LiveMapPreview extends StatelessWidget {
  const LiveMapPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return PulseCard(
      padding: EdgeInsets.zero,
      onTap: () => context.go('/live-map'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 180,
          child: Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(22.7196, 75.8577),
                  initialZoom: 13.0,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.pulse.ta',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: const LatLng(22.7236, 75.8798),
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
                          ),
                          child: const Icon(Icons.local_hospital, color: Colors.white, size: 16),
                        ),
                      ),
                      Marker(
                        point: const LatLng(22.7185, 75.8571),
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
                          ),
                          child: const Icon(Icons.warning, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white.withOpacity(0.92),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Map View',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            'Standard Topology',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.fullscreen, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
