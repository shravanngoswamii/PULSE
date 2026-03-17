import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/features/mission/models/mission_model.dart';
import 'package:pulse_ev/features/mission/providers/mission_provider.dart';
import 'package:pulse_ev/features/mission/screens/mission_setup_screen.dart';
import 'package:pulse_ev/shared/widgets/app_button.dart';
import 'package:pulse_ev/shared/widgets/pulse_map.dart';

class LiveMapScreen extends ConsumerWidget {
  const LiveMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMission = ref.watch(missionProvider);
    final positionAsync = ref.watch(currentPositionProvider);

    // Determine current position as LatLng
    LatLng? currentLatLng;
    final position = positionAsync.valueOrNull;
    if (position != null) {
      currentLatLng = LatLng(position.latitude, position.longitude);
    }

    // No active mission - show plain map view
    if (currentMission == null || currentMission.status != MissionStatus.active) {
      return _buildNoMissionView(context, ref, currentLatLng);
    }

    // Active mission - show full HUD
    return _buildActiveMissionView(context, ref, currentMission, currentLatLng);
  }

  Widget _buildNoMissionView(BuildContext context, WidgetRef ref, LatLng? currentLatLng) {
    final mapCenter = currentLatLng ?? const LatLng(22.7196, 75.8577);
    return Scaffold(
      body: Stack(
        children: [
          PulseMap(
            center: mapCenter,
            currentPosition: currentLatLng,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/dashboard'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppShadows.elevated,
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppShadows.card,
                      ),
                      child: Row(
                        children: [
                          Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('LIVE', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: AppButton(
              text: 'START MISSION',
              variant: ButtonVariant.primary,
              onPressed: () => context.go('/mission/setup'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMissionView(BuildContext context, WidgetRef ref, dynamic currentMission, LatLng? currentLatLng) {
    // Build route coordinates from mission data (backend sends [{lat, lng}] or [[lat, lng]])
    final routeCoords = <LatLng>[];
    for (final coord in currentMission.routeCoordinates) {
      if (coord is List && coord.length >= 2) {
        routeCoords.add(LatLng((coord[0] as num).toDouble(), (coord[1] as num).toDouble()));
      }
    }

    // For auto-drive: use backend-simulated position instead of device GPS
    if (currentMission.isAutoDrive == true &&
        currentMission.currentLat != null &&
        currentMission.currentLng != null) {
      currentLatLng = LatLng(currentMission.currentLat!, currentMission.currentLng!);
    }

    // Destination marker
    final destinationLatLng = LatLng(
      currentMission.destinationHospital.lat,
      currentMission.destinationHospital.lng,
    );

    // Determine map center: prefer current position, then route midpoint
    LatLng? mapCenter = currentLatLng ?? destinationLatLng;
    if (routeCoords.isNotEmpty) {
      mapCenter = routeCoords.first;
    }

    // Build route polyline — only if we have a real road-following route (>2 points)
    // A 2-point route is just a straight line fallback from OSRM failure
    final routePolylines = <Polyline>[];
    if (routeCoords.length > 2) {
      routePolylines.add(
        Polyline(
          points: routeCoords,
          strokeWidth: 6.0,
          color: AppColors.corridorActive,
        ),
      );
    }

    final bool isCalculating = currentMission.isRouteCalculating == true;
    final bool showNotification = currentMission.showHospitalNotification == true;

    return Scaffold(
      body: Stack(
        children: [
          PulseMap(
            center: mapCenter,
            currentPosition: currentLatLng,
            routeCoordinates: const [],
            polylines: routePolylines,
            destinationPosition: destinationLatLng,
            destinationLabel: currentMission.destinationHospital.name,
          ),

          // Top bar with back, status badges
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/dashboard'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: AppShadows.elevated,
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppShadows.card,
                          ),
                          child: Row(
                            children: [
                              Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.emergency, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text('ACTIVE', style: AppTextStyles.caption.copyWith(color: AppColors.emergency, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppShadows.card,
                          ),
                          child: Text(
                            '${currentMission.signalsCleared} signals',
                            style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),

                    // Hospital notification banner
                    if (showNotification)
                      _HospitalNotificationBanner(
                        hospitalName: currentMission.destinationHospital.name,
                      ),

                    // Route calculating indicator
                    if (isCalculating)
                      const _RouteCalculatingBanner(),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.route_rounded, size: 20, color: AppColors.primary),
                              const SizedBox(height: 6),
                              Text(
                                '${currentMission.distance.toStringAsFixed(1)} km',
                                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                              ),
                              Text('Distance', style: AppTextStyles.micro),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.schedule_rounded, size: 20, color: AppColors.primary),
                              const SizedBox(height: 6),
                              Text(
                                currentMission.eta,
                                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                              ),
                              Text('ETA', style: AppTextStyles.micro),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppShadows.card,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentMission.destinationHospital.name,
                                style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Green Corridor Active',
                                style: AppTextStyles.micro.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  GestureDetector(
                    onTap: () async {
                      await ref.read(missionProvider.notifier).endMission();
                      if (context.mounted) {
                        context.go('/dashboard');
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.emergencyGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emergency.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stop_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text('END MISSION', style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated banner showing "Hospital has been notified of your arrival"
class _HospitalNotificationBanner extends StatefulWidget {
  final String hospitalName;
  const _HospitalNotificationBanner({required this.hospitalName});

  @override
  State<_HospitalNotificationBanner> createState() => _HospitalNotificationBannerState();
}

class _HospitalNotificationBannerState extends State<_HospitalNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏥 ${widget.hospitalName}',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hospital notified of your arrival · Start driving',
                      style: AppTextStyles.micro.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated banner showing "Calculating shortest route..."
class _RouteCalculatingBanner extends StatefulWidget {
  const _RouteCalculatingBanner();

  @override
  State<_RouteCalculatingBanner> createState() => _RouteCalculatingBannerState();
}

class _RouteCalculatingBannerState extends State<_RouteCalculatingBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_pulseController),
            child: const Icon(Icons.route_rounded, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text(
            'Calculating shortest route...',
            style: AppTextStyles.label.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
