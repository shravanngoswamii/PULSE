import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../intelligence_controller.dart';

class DistrictMapView extends StatelessWidget {
  final DistrictData district;

  const DistrictMapView({super.key, required this.district});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(district.centerLat, district.centerLng),
                initialZoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.pulse.ta',
                tileProvider: CancellableNetworkTileProvider(),
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(district.centerLat, district.centerLng),
                      radius: 80,
                      color: AppColors.amber.withOpacity(0.35),
                      borderColor: AppColors.amber,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map, color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'DISTRICT VIEW - ${district.sectorName.toUpperCase()}',
                      style: AppTypography.micro.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Column(
                children: [
                  _MapZoomButton(icon: Icons.add, onTap: () {}),
                  const SizedBox(height: 8),
                  _MapZoomButton(icon: Icons.remove, onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }
}
